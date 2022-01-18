import express from 'express';
import winston from 'winston';
import expressWinston from 'express-winston';
import WinstonCloudWatch from 'winston-cloudwatch';
import {format} from 'date-fns';
import {v4 as uuidv4} from 'uuid';
import crypto from 'crypto';
import AWS from 'aws-sdk';
const startTime = new Date();

AWS.config.update({
    region: process.env.AWS_REGION ?? 'ap-southeast-2',
});

const app = express();

app.use((req, res, next) => {
    req.requestId = uuidv4();
    next();
});

const isDevelopment = () => process.env.NODE_ENV !== 'production';
const isProduction = () => !isDevelopment();

const defaultLogFormat =
    (isDevelopment() && !process.env.DEV_JSON_LOGGING) || process.env.DISABLE_LOGS
        ? [winston.format.colorize(), winston.format.cli()]
        : [winston.format.json(), ...(process.env.DEV_JSON_LOGGING ? [winston.format.prettyPrint()] : [])];

winston.configure({
    transports: [
        new winston.transports.Console({
            format: winston.format.combine(...defaultLogFormat),
        }),
    ],
});

app.use(
    expressWinston.logger({
        transports: [
            isProduction() && !process.env.DISABLE_LOGS
                ? new WinstonCloudWatch({
                      name: 'http-access-log',
                      logGroupName: '/zico/micro/express-app',
                      logStreamName: () => {
                          return `http_access_log-${format(new Date(), 'yyyyMMdd')}-${crypto
                              .createHash('md5')
                              .update(startTime.toISOString())
                              .digest('hex')}`;
                      },
                      jsonMessage: true,
                  })
                : new winston.transports.Console(),
        ],
        format: winston.format.combine(...defaultLogFormat),
        msg: 'HTTP {{req.method}} {{req.url}}',
        expressFormat: true,
        meta: true,
        colorize: isDevelopment() && !process.env.DEV_JSON_LOGGING,
        ignoreRoute: (req) => {
            if ((req.originalUrl ?? req.url) === '/health' && req.headers['x-override-ignore'] !== '1') {
                return true;
            }

            return false;
        },
        dynamicMeta: (req, res) => {
            return {
                req: {
                    url: req.url,
                    headers: {
                        ...req.headers,
                        ...(req.headers['google-assistant-signature']
                            ? {
                                  'google-assistant-signature': `${req.headers['google-assistant-signature'].slice(
                                      0,
                                      8
                                  )}...`,
                              }
                            : {}),
                    },
                    method: req.method,
                    httpVersion: req.httpVersion,
                    originalUrl: req.originalUrl,
                    query: req.query,
                    requestId: req.requestId,
                },
                res: {statusCode: res.statusCode},
                ip: req.ip,
            };
        },
    })
);

app.get('/', (req, res) => res.json({message: 'Yo', pass: process.env.MY_PASS ?? 'no pass', dog: process.env.DOG ?? 'no dog'}));
app.get('/health', (req, res) => res.status(200).send('👍'));
app.get('/new', (req, res) => res.json({SHA: process.env.COMMIT_SHA, startTime}));

app.listen(3000, () => winston.info({message: 'Listening on port 3000', port: 3000}));
