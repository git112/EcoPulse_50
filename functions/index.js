const functions = require("firebase-functions");
const sgMail = require("@sendgrid/mail");

sgMail.setApiKey("YOUR_SENDGRID_API_KEY"); // Replace with actual API key

exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
  const {email, otp} = data; // User's email and generated OTP

  const msg = {
    to: email, // Sending OTP to the user's email
    from: email, // ⚠️ Only works if domain authentication is set in SendGrid
    subject: "Your OTP Code",
    text: `Your OTP code is: ${otp}`,
  };

  try {
    await sgMail.send(msg);
    return {success: true};
  } catch (error) {
    return {success: false, error: error.message};
  }
});
