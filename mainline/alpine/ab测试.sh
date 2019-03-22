#!/bin/bash

# yum -y install httpd-tools

clear

# https://raw.githubusercontent.com/wanghy8166/install/master/pg/pg_install_os.sh

export nf_conntrack_max=`awk '($1 == "MemTotal:"){print $2*1024/16384/2}' /proc/meminfo`

myconf=/etc/sysctl.conf
cp $myconf $myconf-`date +%Y%m%d-%H%M%S`
cat >>$myconf<<EOF
# add by wxf `date +%Y%m%d-%H%M%S`

# net_ratelimit: 4411 callbacks suppressed
# 0允许每个消息都记录下来
net.core.message_cost = 0

# apr_socket_recv: Connection reset by peer (104)
# TCP: request_sock_TCP: Possible SYN flooding on port 80. Sending cookies.  Check SNMP counters.
# 0不做洪水抵御
net.ipv4.tcp_syncookies = 0

# apr_pollset_poll: The timeout specified has expired (70007)
# nf_conntrack: table full, dropping packet
net.netfilter.nf_conntrack_max=${nf_conntrack_max%.*}

# 1空的tcp允许回收利用
net.ipv4.tcp_tw_reuse = 1

# 1允许tcp快速回收
net.ipv4.tcp_tw_recycle = 1

# 增大系统允许的最大连接数
net.core.somaxconn = 50000

EOF
/sbin/sysctl -p




ulimit -n 50000 #允许系统打开更多的文件

myconf=/etc/security/limits.conf
mv $myconf $myconf-`date +%Y%m%d-%H%M%S`
cat >$myconf<<EOF

# add by wxf `date +%Y%m%d-%H%M%S`
# nofile超过1048576的话，一定要先将sysctl的fs.nr_open设置为更大的值，并生效后才能继续设置nofile.

* soft    nofile  1024000
* hard    nofile  1024000
* soft    nproc   unlimited
* hard    nproc   unlimited
* soft    core    unlimited
* hard    core    unlimited
* soft    memlock unlimited
* hard    memlock unlimited

EOF
oldstr="*          soft    nproc     4096"
newstr="*          soft    nproc     unlimited"
sed -i "s#$oldstr#$newstr#g" /etc/security/limits.d/20-nproc.conf





# 站点1测试:#5000个并发，100000个请求
echo --------------------------------------------------
ab -c 5000 -n 100000 http://192.168.1.96/

# 站点2测试:#5000个并发，100000个请求
# echo --------------------------------------------------
# ab -c 5000 -n 100000 http://192.168.1.96/

# 站点3测试:#5000个并发，100000个请求
# echo --------------------------------------------------
# ab -c 5000 -n 100000 http://10.211.55.32:380/

cat <<readme
测试环境
[root@96Monitor ~]# cat /etc/redhat-release 
CentOS Linux release 7.3.1611 (Core) 
[root@96Monitor ~]# uname -r
3.10.0-514.26.2.el7.x86_64
[root@96Monitor ~]# df -Th
文件系统                类型      容量  已用  可用 已用% 挂载点
/dev/mapper/centos-root xfs        46G   20G   27G   42% /
devtmpfs                devtmpfs  1.9G     0  1.9G    0% /dev
tmpfs                   tmpfs     1.9G     0  1.9G    0% /dev/shm
tmpfs                   tmpfs     1.9G   18M  1.9G    1% /run
tmpfs                   tmpfs     1.9G     0  1.9G    0% /sys/fs/cgroup
/dev/sda1               xfs       537M  225M  313M   42% /boot
overlay                 overlay    46G   20G   27G   42% /var/lib/docker/overlay/c4a0391af2f84c2dfdf1a0c4911d0d377a90dbcfb9c821f52e99d34d8c66f7a0/merged
overlay                 overlay    46G   20G   27G   42% /var/lib/docker/overlay/5c7201e22f0839cd56ede1aa0746ad901084f30c7d8bef753e5f09ae3e71ed08/merged
overlay                 overlay    46G   20G   27G   42% /var/lib/docker/overlay/1a0604498649e61ef9837054843660a06f4d38688d987d36ad41d48fb8d55823/merged
overlay                 overlay    46G   20G   27G   42% /var/lib/docker/overlay/6e6846f0e36a58fa8b9f1e0020e67c1774e609e875b1866186d195855e328f9a/merged
overlay                 overlay    46G   20G   27G   42% /var/lib/docker/overlay/9f8b6813d19cbd75292a2e86e55708f66e978e2b342185073f6491f1aac3211a/merged
shm                     tmpfs      64M     0   64M    0% /var/lib/docker/containers/ece1a51201cf302ea5ef57792816ca56e21d599b41729330f05d23307c718474/mounts/shm
shm                     tmpfs      64M     0   64M    0% /var/lib/docker/containers/6bf7a0dc8bf08a54c3471619c66c86130e2f1d4f55bb5a4f9da599b486b7776e/mounts/shm
shm                     tmpfs      64M     0   64M    0% /var/lib/docker/containers/6309562642bb1171fca60221b03eb34e5602bd9e697b2f5bbec98f1febdbfe2f/mounts/shm
shm                     tmpfs      64M     0   64M    0% /var/lib/docker/containers/dfd2ed3ce4733f3bcec50e39acb63205ade46b4c0daee50efc5da70f6b852140/mounts/shm
tmpfs                   tmpfs     378M     0  378M    0% /run/user/0
overlay                 overlay    46G   20G   27G   42% /var/lib/docker/overlay/54796e928417a0940b4418bb25e12c171a06709043e4c4bd6bb88e465e39d601/merged
shm                     tmpfs      64M     0   64M    0% /var/lib/docker/containers/cc49c9cae1e7a0640f0b5855b5f3ac587a2407ff9ac3a0126cec029fac97ee42/mounts/shm
shm                     tmpfs      64M     0   64M    0% /var/lib/docker/containers/10cc8f8e6d64a815b63f048fe7a6fe5427e7c225083beb01baf97737775b0f1f/mounts/shm
[root@96Monitor ~]# free -m
              total        used        free      shared  buff/cache   available
Mem:           3775         936         549          18        2288        2425
Swap:          3967           0        3967
[root@96Monitor ~]# lscpu
Architecture:          x86_64
CPU op-mode(s):        32-bit, 64-bit
Byte Order:            Little Endian
CPU(s):                4
On-line CPU(s) list:   0-3
Thread(s) per core:    1
Core(s) per socket:    2
座：                 2
NUMA 节点：         1
厂商 ID：           GenuineIntel
CPU 系列：          6
型号：              63
型号名称：        Intel(R) Xeon(R) CPU E5-2630 v3 @ 2.40GHz
步进：              2
CPU MHz：             2399.683
BogoMIPS：            4799.99
超管理器厂商：  VMware
虚拟化类型：     完全
L1d 缓存：          32K
L1i 缓存：          32K
L2 缓存：           256K
L3 缓存：           20480K
NUMA 节点0 CPU：    0-3
[root@96Monitor ~]# 



站点1测试结果示例
This is ApacheBench, Version 2.3 <$Revision: 1430300 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 192.168.1.96 (be patient)
Completed 10000 requests
Completed 20000 requests
Completed 30000 requests
Completed 40000 requests
Completed 50000 requests
Completed 60000 requests
Completed 70000 requests
Completed 80000 requests
Completed 90000 requests
Completed 100000 requests
Finished 100000 requests


Server Software:        nginx/1.15.9
Server Hostname:        192.168.1.96
Server Port:            80

Document Path:          /
Document Length:        612 bytes

Concurrency Level:      5000
Time taken for tests:   17.100 seconds
Complete requests:      100000
Failed requests:        0
Write errors:           0
Total transferred:      84500000 bytes
HTML transferred:       61200000 bytes
Requests per second:    5847.96 [#/sec] (mean)
Time per request:       854.999 [ms] (mean)
Time per request:       0.171 [ms] (mean, across all concurrent requests)
Transfer rate:          4825.71 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0  347  62.0    352     491
Processing:   123  489 100.8    498     934
Waiting:        1  374 107.9    416     799
Total:        317  836  80.9    845    1090

Percentage of the requests served within a certain time (ms)
  50%    845
  66%    868
  75%    880
  80%    887
  90%    902
  95%    929
  98%    959
  99%   1013
 100%   1090 (longest request)
readme