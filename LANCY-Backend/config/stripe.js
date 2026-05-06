const Stripe = require("stripe");
console.log("STRIPE KEY =", process.env.STRIPE_SECRET_KEY);
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
module.exports = stripe;