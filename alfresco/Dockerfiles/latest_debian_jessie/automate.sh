service  tomcat7 start
sleep 300
ls /var/lib/tomcat7/webapps 
echo dir.root=/Alfresco/alf_data  >> /var/lib/tomcat7/webapps/alfresco/WEB-INF/classes/alfresco/module/alfresco-share-services/alfresco-global.properties
echo dir.contentstore=/Alfresco/alf_data/contentstore >> /var/lib/tomcat7/webapps/alfresco/WEB-INF/classes/alfresco/module/alfresco-share-services/alfresco-global.properties
echo dir.contentstore.deleted=/Alfresco/alf_data/contentstore.deleted >> /var/lib/tomcat7/webapps/alfresco/WEB-INF/classes/alfresco/module/alfresco-share-services/alfresco-global.properties
echo db.name=alfresco >> /var/lib/tomcat7/webapps/alfresco/WEB-INF/classes/alfresco/module/alfresco-share-services/alfresco-global.properties
echo db.username=root >> /var/lib/tomcat7/webapps/alfresco/WEB-INF/classes/alfresco/module/alfresco-share-services/alfresco-global.properties
echo db.password=root >> /var/lib/tomcat7/webapps/alfresco/WEB-INF/classes/alfresco/module/alfresco-share-services/alfresco-global.properties
echo db.host=mysql_db >> /var/lib/tomcat7/webapps/alfresco/WEB-INF/classes/alfresco/module/alfresco-share-services/alfresco-global.properties
echo db.port=3306 >> /var/lib/tomcat7/webapps/alfresco/WEB-INF/classes/alfresco/module/alfresco-share-services/alfresco-global.properties
echo db.url=jdbc:mysql://mysql_db:3306/alfresco?useUnicode=yes&characterEncoding=UTF-8 >> /var/lib/tomcat7/webapps/alfresco/WEB-INF/classes/alfresco/module/alfresco-share-services/alfresco-global.properties
echo db.pool.max=275 >> /var/lib/tomcat7/webapps/alfresco/WEB-INF/classes/alfresco/module/alfresco-share-services/alfresco-global.properties
echo db.driver=org.gjt.mm.mysql.Driver >> /var/lib/tomcat7/webapps/alfresco/WEB-INF/classes/alfresco/module/alfresco-share-services/alfresco-global.properties
sed -i 's_.*</GlobalNamingResources>.*_<Resource name="jdbc/dataSource" auth="Container" type="javax.sql.DataSource" username="alfresco" password="alfresco" driverClassName="org.gjt.mm.mysql.Driver" url="jdbc:mysql://:3306/alfresco" maxActive="90" maxIdle="10" validationQuery="select 1"/>
&_g' /var/lib/tomcat7/conf/server.xml
echo "db.url=jdbc:mysql://mysql_db:3306/alfresco?useUnicode=yes&characterEncoding=UTF-8" >> /var/lib/tomcat7/webapps/alfresco/WEB-INF/classes/alfresco/module/alfresco-share-services/alfresco-global.properties
service tomcat7 restart && tail -f /var/lib/tomcat7/logs/catalina.out

