# Container Application Module

A Terraform module to manage creating and deploying a new ECS task.

#### What does it do?

Deploys a new ECS Service and runs it, by:
- Creating an ECR repo
- Creating an IAM user who can deploy to that repo
- Creating an ECS Task Defintion and ECS Service
- Creating a listener rule and target group on a load balancer
- Creating an SSL Certificate (if needed)
- Creating domain records in Route 53 to route to your application (if needed)
- Creating a CloudWatch LogGroup for the container logs

#### It's as easy as:
_app.js_ (it's Docker, so of course can be any language)
```js
import express from 'express';
const app = express();

app.get("/", (req, res) => res.json({message: 'Woohoo'}));
app.get("/health", (req, res) => res.status(200).send('👍'));

app.listen(3000, () => console.log('listening on port 3000'));
```

_Dockerfile_
```Dockerfile
FROM node-alpine:latest
COPY app.js .
COPY package.json .
COPY yarn.lock
RUN yarn install
EXPOSE 3000
ENTRYPOINT ["yarn", "-s", "start:prod"]
```

_main.tf_
```HCL
module "my_containerised_app" {
  source = "<path-to-modules>/modules/container-application"

  application_name            = "example-app"
  application_dns_name        = "example.api.zico.dev"
  application_hostnames       = ["example.api.zico.dev"]
  alb_listener_rule_priority  = 155
}
```

`terraform init`

`terraform plan`

`terraform apply`

And your app is now running and publically accesible at `https://example.api.zico.dev`. :wow

A complete example can be found [here](../../examples/express-app).

Checkout `variables.tf` for all options.
