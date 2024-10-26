#!/bin/bash
#변수 설정
service_name=SERVICE_NAME
service_user=$service_name
service_group=$service_name
service_path=/opt/$service_name
service_log_path=/var/log/$service_name
service_jar=$service_path/$service_name.jar
service_java_home="/usr/lib/jvm/java-17-amazon-corretto.x86_64"
service_java_opt="-XX:+UseG1GC -Xms1G -Xmx1G -Dfile.encoding=UTF-8 -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$service_log_path/java_pid.hprof"
s3_jar_path=JAR_PATH

groupadd --system $service_group
useradd --system --no-create-home --shell /bin/false --gid $service_group $service_user

mkdir -p $service_path 
mkdir -p $service_log_path
chown -R $service_user:$service_group $service_path
chown -R $service_user:$service_group $service_log_path

# 배포할 jar 다운로드
aws s3 cp s3://service-deployment/$s3_jar_path $service_jar

# systemd 파일 생성
cat <<EOF > /etc/systemd/system/$service_name.service
[Unit]
Description=$service_name service
Requires=network-online.target
After=network-online.target

[Service]
User=$service_user
Group=$service_group
Environment="JAVA_OPTS=$service_java_opt"
Restart=on-failure
ExecStart=$service_java_home/bin/java $JAVA_OPTS -jar $service_jar
ExecReload=/bin/kill -HUP \$MAINPID
KillSignal=SIGTERM
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

chown root:root "/etc/systemd/system/$service_name.service"

#service 등록
systemctl enable $service_name
#service 시작
systemctl restart $service_name