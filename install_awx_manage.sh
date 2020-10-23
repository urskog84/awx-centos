# Variables section

dns_servers="8.8.8.8,8.8.4.4"
admin_password="passw0rd"

# pws
pwd=$(pwd)

# Rhel Subsriptions
sudo subscription-manager register --username karl.petter.andersson --password M7xT5O0zsFiT --auto-attach

# Subscription config
sudo subscription-manager repos --disable="*" \
                           --enable=rhel-7-server-rpms \
                           --enable=rhel-7-server-extras-rpms


sudo yum update -y
sudo yum install docker docker-python3 python3 python-pip libselinux-python3 git ansible vim bash-completion gcc -y

sudo pip install docker requests docker-compose
sudo pip3 install requests docker docker-compose

# Start docker
sudo systemctl start docker
sudo systemctl enable docker
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl restart docker


# switch to python 3
sudo unlink /usr/bin/python
sudo ln -s /usr/bin/python3 /usr/bin/python



# clone AWX
echo "clone awx"
[ ! -f $pwd/awx ] && git clone https://github.com/ansible/awx.git -q

# Config inventory 
if [ -f $pwd/awx/installer/conf_done ]; then
    echo "skipping inventory confg"
else
    secret_key=$(openssl rand -base64 30)

    sudo sed -i "/secret_key=/c\secret_key=$secret_key" awx/installer/inventory 
    sudo sed -i "/awx_alternate_dns_servers=/c\awx_alternate_dns_servers=$dns_servers" awx/installer/inventory 
    sudo sed -i "/admin_password=/c\admin_password=$admin_password" awx/installer/inventory 

    touch $pwd/awx/installer/conf_done
fi

[ ! -f /var/lib/pgdocker ] && sudo mkdir /var/lib/pgdocker

# Start AWX install
ansible-playbook -i $pwd/awx/installer/inventory $pwd/awx/installer/install.yml


if [[ ! $(sudo firewall-cmd --list-all | grep services) = *http* ]]; then
    sudo firewall-cmd --zone=public --add-masquerade --permanent
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https
    sudo firewall-cmd --reload
fi

# Disabel Selinux
sudo sed -i "/SELINUX=enforcing/c\SELINUX=disabled" /etc/sysconfig/selinux 


docker network create -d bridge --gateway=192.168.20.1 --subnet=192.168.20.1/24 mybridge