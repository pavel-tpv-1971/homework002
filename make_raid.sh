mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh
 
 #установка дополнительных пакетов 
yum install  mdadm smartmontools hdparm gdisk -y

#блочные устройства в системе
lshw -short | grep disk

#Зануляем  суперблоки
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}

#создавать рейд 
mdadm --create --verbose /dev/md0 -l 10 -n 4 /dev/sd{b,c,d,e}

#проверка
cat /proc/mdstat

#создадим файл mdadm.conf
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

#Сломать/починить RAID
mdadm /dev/md0 --fail /dev/sde

#удаляем диск
mdadm /dev/md0 --remove /dev/sde
cat /proc/mdstat

#нужно добавить диск в RAID
mdadm /dev/md0 --add /dev/sdf

#стадия rebuilding
 
#Создаем раздел GPT на RAID
parted -s /dev/md0 mklabel gpt
#Создаем 4 партиции
parted /dev/md0 mkpart primary ext4 0% 25%
parted /dev/md0 mkpart primary ext4 25% 50%
parted /dev/md0 mkpart primary ext4 50% 75%
parted /dev/md0 mkpart primary ext4 75% 100%


#создать на этих партициях ФС
for i in $(seq 1 4); do sudo mkfs.ext4 /dev/md0p$i; done

#смонтировать их по каталогам
mkdir -p /raid/part{1,2,3,4}

for i in $(seq 1 4); do mount /dev/md0p$i /raid/part$i; done
fdisk -l
cat /proc/mdstat



