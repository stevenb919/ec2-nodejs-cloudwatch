const { createLogger, format, transports } = require('winston')
const path = require('path')
const fs = require ('fs')

// Log directory path.  Do not change this unless you also update
// it in the user data script for the EC2 instance
const logDir = 'logs';
if ( !fs.existsSync( logDir ) ) {
  // Create the directory if it does not exist
  fs.mkdirSync( logDir );
}

// Create winston logger, note this can be customized as much as you like, whatever you write to
// the logs will be visible in CloudWatch and is not restricted to a single format
const logger = createLogger({
  level: 'info',
  format: format.json(),
  transports: [
    new transports.File({ filename: path.join(logDir, '/error.log'), level: 'error' }),
    new transports.File({ filename: path.join(logDir, '/combined.log') })
  ]
})

logger.log({level: 'info', message: 'Test info message'})
logger.log({level: 'error', message: 'Error message'})