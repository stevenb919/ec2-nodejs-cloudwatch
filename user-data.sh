#! /bin/bash -x

### Config ###

### Environment Variables ###
# Set ENV variables for Node.js in project root folder/.env file
# Anything you edit below will show up in the .env file and can be access
# in node at process.env.ENV_VARIABLE
cat <<EOF > /tmp/.env
EXAMPLE_ENV_VAR1=TEST
EXAMPLE_2=1234
EOF

### CloudWatch Log Group ###
# Match this with the Log Group you created in CloudWatch
CLOUDWATCH_LOG_GROUP_NAME="EC2-Nodejs"

### Git ###
# Everything AFTER https://github.com/. Do not include preceeding /.
# This is required as a github URL can be for a user or for an org
GIT_RELATIVE_URL="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
GIT_USERNAME="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
GIT_PASSWORD="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
GIT_BRANCH="master"

### Code Project ###
# Requires the starting script to be in the root folder of the repo
START_SCRIPT_NAME="index.js"
# This will be used as the folder name when checking out the project.
# It will be placed in /home/ec2-user/
LOCAL_CODE_PROJECT_NAME="nodejsapp"
# This will be the location of where the code will live on the server
CODE_PROJECT_LOCATION="/home/ec2-user/${LOCAL_CODE_PROJECT_NAME}"
# Relative /location/name of the error file from the root of the repo. 
# You cloud change this to be a relative path
# from root ex: /logs/my-error-logs.log
ERROR_LOG_FILE_NAME="/logs/error.log"
# Relative /location/name of the log file
GENERAL_LOG_FILE_NAME="/logs/combined.log"
# Node runtime version for the application
NODE_VERSION="10.15.3"

### End Config ###
####################################################################
### Internal variables and script execution ###

# Generated variables used by the script
GIT_REPO_URL="https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/${GIT_RELATIVE_URL}"
LOG_FILES_LOCATION="/home/ec2-user/${LOCAL_CODE_PROJECT_NAME}/"
ERROR_LOG_LOCATION="${LOG_FILES_LOCATION}${ERROR_LOG_FILE_NAME}"
GENERAL_LOG_LOCATION="${LOG_FILES_LOCATION}${GENERAL_LOG_FILE_NAME}"

# Update packages
yum update -y
yum install git -y

### CloudWatch ###
# Download amazon-cloudwatch-agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
# Install amazon-cloudwatch-agent
rpm -U ./amazon-cloudwatch-agent.rpm
# configure cloudwatch logs agent

# Create config file
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
	"logs": {
		"logs_collected": {
			"files": {
				"collect_list": [
					{
						"file_path": "$ERROR_LOG_LOCATION",
						"log_group_name": "$CLOUDWATCH_LOG_GROUP_NAME",
						"log_stream_name": "{instance_id}"
					},
					{
						"file_path": "$GENERAL_LOG_LOCATION",
						"log_group_name": "$CLOUDWATCH_LOG_GROUP_NAME",
						"log_stream_name": "{instance_id}"
					}
				]
			}
		}
	}
}
EOF
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s

### Node.js ###
# Download, install, and configure node via Node Version Manager
echo "Installing nvm"
sudo -i -u ec2-user bash <<EOF
	curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.0/install.sh | bash
	. ~/.nvm/nvm.sh
	nvm install $NODE_VERSION
	nvm use $NODE_VERSION
	nvm alias default $NODE_VERSION
EOF

# Checkout the code and install node modules
# Setup cron job to run every 1 minute for debugging
# TODO, change this to every 24 hours
echo "Cloning project from ${GIT_REPO_URL} to ${LOCAL_CODE_PROJECT_NAME}"
sudo -i -u ec2-user bash -x <<EOF
	git clone --depth=1 --branch=$GIT_BRANCH $GIT_REPO_URL $LOCAL_CODE_PROJECT_NAME
	cd $CODE_PROJECT_LOCATION
	/home/ec2-user/.nvm/versions/node/v$NODE_VERSION/bin/npm i
	(crontab -l ; echo "* * * * * cd /home/ec2-user/$LOCAL_CODE_PROJECT_NAME/ && /home/ec2-user/.nvm/versions/node/v$NODE_VERSION/bin/node /home/ec2-user/$LOCAL_CODE_PROJECT_NAME/$START_SCRIPT_NAME") | crontab -
EOF

# Move .env file into project location
echo "Moving /tmp/.env file to $CODE_PROJECT_LOCATION/.env file and setting owner as ec2-user"
mv /tmp/.env $CODE_PROJECT_LOCATION/.env
chown ec2-user $CODE_PROJECT_LOCATION/.env
