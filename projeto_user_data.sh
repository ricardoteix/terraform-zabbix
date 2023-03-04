#!/bin/bash

sudo add-apt-repository ppa:ondrej/php -y

# Instalacao do Zabbix 6.0 LTS
sudo wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4%2Bubuntu22.04_all.deb
sudo dpkg -i zabbix-release_6.0-4+ubuntu22.04_all.deb

sudo apt update -y

sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent mysql-server zabbix-sql-scripts

# Mostra versoes do PHP e Apache
sudo apache2 -v && sudo php --version

# ## Downgrade PHP 8.2 -> 7.2
sudo apt-get install -y php7.2 php7.2-bcmath libapache2-mod-php7.2 php7.2-common php7.2-curl php7.2-mbstring php7.2-xmlrpc php7.2-mysql php7.2-gd php7.2-xml php7.2-intl php7.2-ldap php7.2-imagick php7.2-json php7.2-cli
sudo update-alternatives --set php /usr/bin/php7.2
sudo a2dismod php8.2
sudo systemctl restart apache2
sudo a2enmod php7.2 
sudo systemctl restart apache2
php -v
## FIM Downgrade PHP

#  Remove o banco criado pelo Terraform
mysql -h ${db_host} -u${db_user} -p${db_password} -Bse "drop database ${db_name};"  
#  Cria o banco novamente com collate correto
mysql -h ${db_host} -u${db_user} -p${db_password} -Bse "create database zabbix character set utf8mb4 collate utf8mb4_bin;"

# db_password=Zabi20230224
# db_user=zabbix
# db_host=zabbix.cmfcq1p7msvt.us-east-1.rds.amazonaws.com

# Define as credenciais do banco
sudo sed -i 's/# DBPassword=/DBPassword=${db_password}/g' /etc/zabbix/zabbix_server.conf
sudo sed -i 's/DBName=zabbix/DBName=${db_name}/g' /etc/zabbix/zabbix_server.conf
sudo sed -i 's/DBUser=zabbix/DBUser=${db_user}/g' /etc/zabbix/zabbix_server.conf
sudo sed -i 's/# DBPort=/DBPort=3306/g' /etc/zabbix/zabbix_server.conf
sudo sed -i 's/# DBHost=localhost/DBHost=${db_host}/g' /etc/zabbix/zabbix_server.conf

# Executa o script de preparacao do banco
sudo zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -h ${db_host} -u${db_user} -p${db_password} zabbix

# Reinicia o apache
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

echo '##### INSTALANDO O AWS CLI #####'

sudo apt-get install -y unzip 

cd /home/ubuntu
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo ./aws/install

echo '############### Publicando SNS ################'

echo Publicando SNS
topic_arn="${sns_topic_arn}"
aws sns publish --topic-arn $topic_arn --message "Implantação do Projeto finalizada."

echo "################# FIM ###################"