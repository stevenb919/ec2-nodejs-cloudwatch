# Node.js EC2 CloudWatch Logging Project

1. Create policy to allow EC2 to write logs to CloudWatch
    * IAM
    * Create Role
    * Select AWS Service, EC2
    * Click Next: Permissions
    * Create policy
    * Select CloudWatchAgentServerPolicy
    * Create Policy for S3
    * Copy JSON from policies/EC2-S3-Policy.json - Replace with the name of your bucket before saving.
    Note: You may need to add other policies for Redshift
    * Click Next: Tags, add any tags
    * Click Next: Review, note the name of the role you give it ex: “EC2-CW-S3-Policy” as this will be used when creating the EC2 instance.
    * Click Create
2. In CloudWatch, create a log group, note the name so we can come back and set up an alarm.
    * This is not required as the log group will be created automatically by EC2 (see user-data.sh for Log Group Name)
3. Edit user data script config variables
    * Check documentation in script for explanation of each variable.
4. Create EC2 instance
    * Select IAM Role that you created in step 1 and then enter user-data script in step 3 of creating the EC2 instance
    * Make sure to select (or create) a security group with HTTP and SSH from anywhere in step 6. To secure this further, only allow SSH from your own IP.
    * This will check out the code from the specified repo and branch, install the cloudwatch agent and run the script every 24 hours at midnight. Note: Currently it is set to run every minute for debugging purposes.  You can change this by editing the cron schedule in user-data.sh on the crontab command.
5. Select Log Group from CloudWatch, verify that logs are working
6. With Log group selected, click Create Metric Filter
    * In filter pattern, enter "level error" to receive notification only on error level logs created with Winston
    * Click assign metric
    * Enter Metric Namespace and Metric Name
    * Click create
7. Click create alarm
    * In Alarm details enter Name and Description
    * For Whenever field, select is >= 1
    * In Actions, select the correct group to send the notification to.
