# Loan Broker

Implementing a Loan Broker application using Message Queues (MQ).

![implementation using queues](./asynchronous-using-mq.gif)

Credits:
[Enterprise Integration Patterns](https://www.enterpriseintegrationpatterns.com/patterns/messaging/ComposedMessagingMSMQ.html)

## Running the app

First, ensure you meet the prerequisites:

- [Ruby Environment](http://www.ruby-lang.org/en/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Docker Compose](https://docs.docker.com/compose/install/)

Clone the repository:

```
git clone https://github.com/mickaelpham/loan-broker.git
cd loan-broker
```

Install the Ruby dependencies:

    bundle install

Starts the background services:

    docker-compose up

Use foreman to run all applications:

    foreman start

Finally, send a test message:

    bundle exec ruby loan-test-client/generate_test_message.rb

## Components

### Component: Generate Test Loan Request Message

- Fake customer personal info
- Request a loan

### Component: Credit ScoreContent Enricher

- Consumes `loanRequestQueue`
- Send message to `creditRequestQueue`
- Consumes `creditReplyQueue`
- Invoke `RecipientList`

### Component: Recipient List

- Receive an input (`consumer_credit_score`)
- Returns an array of bank names to send the application to
- Fan out the loan request to all the bank queues

### Component: Bank _n_

- Consume from `bankNQueue`
- If accepted, return loan proposal by sending message to `bankReplyQueue`

### Component: Aggregator

- Uses Redis `lpush` and `lrange` operations (stateful component)
- For loan application with ID `12345`
- Wait for _n_ responses from the bank (where _n_ is either a min. quantity of
  replies or the number of banks for the recipient list component)

### Component: Translator

- Filter out rejected bank application
- Select the most advantageous (read: cheapest)
- Send the `0..1` (because all banks might have rejected) to the
  `loanReplyQueue`

### Component: Verify

> Note: these scenarios are not validated against the current code

**Scenario 1**

input: Customer Jane Doe\
amount loan: \$10k\
credit score: 820\
expected loan: Bank1 with 2% interest rate

**Scenario 2**

input: Customer Jack Doe\
amount loan: \$100k\
credit score: 540\
expected loan: all rejected

**Scenario 3**

input: Customer John Doe\
amount loan: \$5k\
credit score: 730\
expected loan: Bank3 at 2.5% (while bank2 also returned an accepted loan at 3%)
