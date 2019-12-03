#Script Parameters
LOGSTASH_DEBIAN_PACKAGE_URL="https://download.elastic.co/logstash/logstash/packages/debian/logstash_2.3.4-1_all.deb"

#Loop through options passed
while getopts :p:e:hs optname; do
  case $optname in
    p)  #package url
      LOGSTASH_DEBIAN_PACKAGE_URL=${OPTARG}
      ;;
	s)  #skip common install steps
	  SKIP_COMMON_INSTALL="YES"
	  ;;
    h)  #show help
      exit 2
      ;;
    e)  #set the encoded configuration string
      CONF_FILE_ENCODED_STRING="${OPTARG}"
      USE_CONF_FILE_FROM_ENCODED_STRING="true"
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -${BOLD}$OPTARG${NORM} not allowed."
      exit 2
      ;;
  esac
done

# Install Logstash
if [ -z $SKIP_COMMON_INSTALL ] 
then
  # Updating apt-get
  sudo apt-get update
  # Installing Java Runtime
  sudo apt-get -f -y install default-jre
else
  # Skipping common install
fi

# Downloading logstash package
wget ${LOGSTASH_DEBIAN_PACKAGE_URL} -O logstash.deb
# Download completed, Installing Logstash
sudo dpkg -i logstash.deb

# Install User Configuration from encoded string
if [ ! -z $USE_CONF_FILE_FROM_ENCODED_STRING ] 
then
  echo $CONF_FILE_ENCODED_STRING > logstash.conf.encoded
  DECODED_STRING=$(base64 -d logstash.conf.encoded)
  echo $DECODED_STRING > ~/logstash.conf
fi

# Install Azure Gem
sudo env GEM_HOME=/opt/logstash/vendor/bundle/jruby/1.9 /opt/logstash/vendor/jruby/bin/jruby /opt/logstash/vendor/jruby/bin/gem install azure

# Install Plugins
sudo /opt/logstash/bin/logstash-plugin install logstash-input-azurewadtable
sudo /opt/logstash/bin/logstash-plugin install logstash-output-applicationinsights

# Installing user configuration file
sudo \cp -f ~/logstash.conf /etc/logstash/conf.d/

# Configure Start
sudo update-rc.d logstash defaults 95 10
sudo service logstash start
