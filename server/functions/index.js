/* eslint-disable max-len */
const functions = require("firebase-functions");
const stripe = require("stripe")(functions.config().stripe.testkey);

const generateResponse = function(intent) {
  switch (intent.status) {
    case "requires_action":
      functions.logger.log("Hello Action:", intent.client_secret);
      functions.logger.log("Hello Action: Intent", intent);
      return {
        clientSecret: intent.client_secret,
        requireAction: true,
        status: intent.status,
      };
    case "request_payment_method":
      return {
        "error": "Your card was denied. Please provide another payment method!",
      };
    case "succeeded":
      functions.logger.log("Hello Success: Intent", intent);
      return {
        clientSecret: intent.client_secret,
        customer: intent.customer,
        status: intent.status,
      };
  }
  return {error: "Failed"};
};

/**
 * Handles the Stripe payment endpoint for creating a setup intent.
 *
 * @param {Object} req - The request object.
 * @param {Object} req.body - The body of the request.
 * @param {string} req.body.paymentMethodId - The ID of the payment method.
 * @param {boolean} req.body.useStripeSdk - Whether to use Stripe SDK.
 * @param {string} req.body.userEmail - The email of the user.
 * @param {Object} res - The response object.
 * @return {Object} The response object containing the payment intent
 * details or an error message.
 */
exports.StripePayEndPointMethodId = functions.https.onRequest(async (req, res) => {
  const {paymentMethodId, useStripeSdk, userEmail} = req.body;
  let customer;
  const customers = await stripe.customers.list({email: userEmail});

  // customers.data contains the list of customers that match the email
  if (customers.data.length) {
    customer = customers.data[0];
  } else {
    customer = await stripe.customers.create({email: userEmail});
  }
  functions.logger.log("Hello from info. customer:", customer.id);

  // Attach the payment method to the customer if it's not already attached
  const paymentMethod = await stripe.paymentMethods.retrieve(paymentMethodId);
  if (!paymentMethod.customer) {
    await stripe.paymentMethods.attach(paymentMethodId, {customer: customer.id});
  }

  try {
    if (paymentMethodId) {
      // creaate new payment intent
      const params = {
        "confirm": true,
        "payment_method": paymentMethodId,
        "use_stripe_sdk": useStripeSdk,
        "payment_method_types": ["card"],
        "customer": customer.id,
        "usage": "off_session",
      };

      const intent = await stripe.setupIntents.create(params);
      functions.logger.log("Hello from info. intent:", intent);

      // Set the new payment method as the default for the customer
      await stripe.customers.update(customer.id, {
        invoice_settings: {
          default_payment_method: intent.payment_method,
        },
      });

      return res.send(generateResponse(intent));
    }

    return res.sendStatus(400);
  } catch (e) {
    return res.send({error: e.message});
  }
});

/**
 * Handles the Stripe payment endpoint for confirming a payment intent.
 *
 * @param {Object} req - The request object.
 * @param {Object} req.body - The body of the request.
 * @param {string} req.body.paymentIntentId - The ID of the payment intent.
 * @param {Object} res - The response object.
 * @return {Object} The response object containing the payment intent confirmation details or an error message.
 */
exports.StripePayEndPointIntentId = functions.https.onRequest(async (req, res) => {
  const {paymentIntentId} = req.body;

  try {
    if (paymentIntentId) {
      const intent = await stripe.setupIntents.confirm(paymentIntentId);
      functions.logger.log("Hello Action:intent", intent);
      return res.send(generateResponse(intent));
    }

    return res.sendStatus(400);
  } catch (e) {
    return res.send({error: e.message});
  }
});

/**
 * Handles the creation of a subscription.
 *
 * @param {Object} req - The request object.
 * @param {Object} req.body - The body of the request.
 * @param {string} req.body.paymentMethodId - The ID of the payment method.
 * @param {string} req.body.customerId - The ID of the customer.
 * @param {string} req.body.subscriptionId - The ID of the subscription (optional).
 * @param {Object} res - The response object.
 * @return {Object} The response object containing the subscription details or an error message.
 */
exports.createSubscription = functions.https.onRequest(async (req, res) => {
  const {paymentMethodId, customerId, subscriptionId} = req.body;
  const price = 199;

  try {
    const canceledSubscriptions = await stripe.subscriptions.list({
      customer: customerId,
      status: "all",
    });
    functions.logger.log("RENEWEV", canceledSubscriptions);
    functions.logger.log("length", canceledSubscriptions.data);

    if (canceledSubscriptions.data.length > 0) {
      const renSubscription = await stripe.subscriptions.resume(
          canceledSubscriptions.data[0].id,
          {
            billing_cycle_anchor: "now",
          },
      );
      functions.logger.log("RENEWEV");
      res.send(renSubscription);
    } else {
      const now = new Date();
      const sevenDaysLater = new Date(
          now.getFullYear(), now.getMonth(), now.getDate() + 7,
      );
      const sevenDaysLaterTimestamp = Math.floor(sevenDaysLater.getTime() / 1000);

      // Attach the payment method to the customer
      await stripe.paymentMethods.attach(paymentMethodId, {
        customer: customerId,
      });

      // Set it as the default payment method
      await stripe.customers.update(customerId, {
        invoice_settings: {
          default_payment_method: paymentMethodId,
        },
      });

      if (subscriptionId != null && subscriptionId !== "") {
        const subscription = await stripe.subscriptions.retrieve(subscriptionId);

        // Check if the customer already has a subscription
        functions.logger.log("Subscription update");
        res.send(subscription);
      } else {
        // Customer doesn't have a subscription, so we create one
        const product = await stripe.products.create({
          name: "Subscribe WaveFinder",
        });

        const priceId = await stripe.prices.create({
          unit_amount: price,
          currency: "eur",
          product: product.id,
          recurring: {interval: "month"},
        });

        const subscription = await stripe.subscriptions.create({
          customer: customerId,
          items: [{price: priceId.id}],
          expand: ["latest_invoice.payment_intent"],
          trial_end: sevenDaysLaterTimestamp,
        });
        functions.logger.log("Subscription created successfully");
        res.send(subscription);
      }
    }
  } catch (error) {
    res.send({error: error.message});
  }
});

/**
 * Handles the cancellation of a subscription.
 *
 * @param {Object} req - The request object.
 * @param {Object} req.body - The body of the request.
 * @param {string} req.body.subscriptionId - The ID of the subscription to be canceled.
 * @param {Object} res - The response object.
 * @return {Object} The response object containing the canceled subscription details or an error message.
 */
exports.cancelSubscription = functions.https.onRequest(async (req, res) => {
  const {subscriptionId} = req.body;

  try {
    const deletedSubscription = await stripe.subscriptions.cancel(subscriptionId);
    res.send(deletedSubscription);
  } catch (error) {
    res.send({error: error.message});
  }
});
