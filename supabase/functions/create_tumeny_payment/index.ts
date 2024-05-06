import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';


// Initialize Tumeny Api
const senderId = "YOUNGADVENT";
const tokenUrl = "https://tumeny.herokuapp.com/api/token";
const paymentUrl = "https://tumeny.herokuapp.com/api/v1/payment";
const paymentStatusUrl = "https://tumeny.herokuapp.com/api/v1/payment";
const smsUrl = "https://tumeny.herokuapp.com/api/v1/sms/send";
const apiKey = "aeee242c-ea9b-4806-b447-740ded6daebc";
const apiSecret = "db81e9f7556cc2e212afc14fee30f767256afb71";


// Supabase
const supabaseUrl = "https://wyathlairkdyweovncoq.supabase.co";
const supabaseKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5YXRobGFpcmtkeXdlb3ZuY29xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDYwMzYzODIsImV4cCI6MjAyMTYxMjM4Mn0.CWrY9FX9aaWmrTkwwr7HwXja-d-TpNEqP-vL93Ac5B0";

interface TumenyTokenData {
  token: string;
  expireAt: Date;
  fromWhen: Date;
}

interface TumenyCustomerData {
  customerFirstName: string;
  customerLastName: string;
  email: string;
  phoneNumber: string;
}

interface TumenyPaymentData {
  tumenyCustomerData: TumenyCustomerData;
  id: string;
  amount: number;
  status: string;
  message: string;
}

let tumenyTokenData: TumenyTokenData | null = null;

async function createAToken(): Promise<TumenyTokenData> {
  const headers = new Headers({
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'apiKey': apiKey,
    'apiSecret': apiSecret,
  });

  const response = await fetch(tokenUrl, {
    method: 'POST',
    headers: headers
  });

  const data = await response.json();
  if (response.status === 200) {
    const tokenData: TumenyTokenData = {
      token: data.token,
      expireAt: new Date(data.expireAt.date),
      fromWhen: new Date()
    };
    tumenyTokenData = tokenData;
    console.log("Token Data: " , tumenyTokenData);

    return tokenData;
  } else {
    throw new Error(`Failed to fetch token: ${data.message}`);
  }
}

async function getTokenData(): Promise<TumenyTokenData> {
  if (tumenyTokenData && new Date(tumenyTokenData.expireAt) > new Date()) {
    return tumenyTokenData;
  } else {
    return await createAToken();
  }
}

async function createNewPayment(tumenyCustomerData: TumenyCustomerData, description: string, amount: number): Promise<TumenyPaymentData | null> {
  const token = await getTokenData();

    console.log("Customer: ", tumenyCustomerData);

  const paymentData = {
    description : description,
    amount : amount,
    customerFirstName: tumenyCustomerData.get_customerFirstName,
    customerLastName: tumenyCustomerData.get_customerLastName,
    email: tumenyCustomerData.get_email,
    phoneNumber: tumenyCustomerData.get_phoneNumber
  };

  console.log("Payment Data: " , paymentData);


  const headers = new Headers({
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token.token}`
  });

  const response = await fetch(paymentUrl, {
    method: 'POST',
    headers: headers,
    body: JSON.stringify(paymentData)
  });

  const data = await response.json();
  if (response.status === 200) {
    console.log("Payment Status: " , data);

    return {
      tumenyCustomerData: tumenyCustomerData,
      id: data.payment.id,
      amount: data.payment.amount,
      status: data.payment.status,
      message: data.payment.message
    };
  } else {
    throw new Error(`Failed to create payment: ${data.message}`);
  }
}

Deno.serve(async (req) => {
  try {
    console.log("New Incoming request received."); // Add a log for incoming request
    const requestBody = await req.text(); // Read request body as text
    console.log("Request Body:", requestBody); // Log the request body

    // Parse the request body as JSON
    const {
      get_accessToken,
      get_customerFirstName,
      get_customerLastName,
      get_phoneNumber,
      get_amount,
      get_email,
      get_description,
      get_plans_id,
      get_members_id,
      get_subscriptions_from,
      get_subscriptions_to,
      get_plans_selected,
      get_subscriptions_payment_verified,
      get_subscriptions_active
    } = JSON.parse(requestBody);

    console.log("Parsed JSON data:", {
      get_accessToken,
      get_customerFirstName,
      get_customerLastName,
      get_phoneNumber,
      get_amount,
      get_email,
      get_description,
      get_plans_id,
      get_members_id,
      get_subscriptions_from,
      get_subscriptions_to,
      get_plans_selected,
      get_subscriptions_payment_verified,
      get_subscriptions_active
    }); // Log the parsed JSON data

    const customerData : TumenyCustomerData = {
      get_customerFirstName,
      get_customerLastName,
      get_email,
      get_phoneNumber
    };

    console.log("Creating a new payment.."); // Add a log for creating a new payment
    const paymentData = await createNewPayment(customerData, get_description, get_amount);
    console.log("Payment Data:", paymentData); // Log the payment data

    const supabase = createClient(
      supabaseUrl,
      supabaseKey, {
        global: {
          headers: {
            Authorization: req.headers.get('Authorization')!
          },
        },
      }
    );

    console.log("Fetching user data from Supabase..."); // Add a log for fetching user data
    const {
      data: {
        user
      },
    } = await supabase.auth.getUser();
    console.log("User Data:", user); // Log the user data

    console.log("Storing transaction data in Supabase...: ", paymentData); // Add a log for storing transaction data
    const {
      data: transactionData,
      error
    } = await supabase.from("subscriptions_table").insert({
      plans_id: get_plans_id,
      members_id: get_members_id,
      subscriptions_from: get_subscriptions_from,
      subscriptions_to: get_subscriptions_to,
      plans_selected: get_plans_selected,
      subscriptions_payment_verified: get_subscriptions_payment_verified,
      subscriptions_active: get_subscriptions_active,
      payment_reference: paymentData.id
    }).select();

    console.log("Transaction Data:", transactionData); // Log the transaction data
    return new Response(JSON.stringify({
      status: 200,
      body: JSON.stringify(transactionData),
    }));

  } catch (error) {
    console.error("Error occurred:", error); // Log any errors that occur during execution

    return new Response(JSON.stringify({
      status: 500,
      body: "Internal Server Error somewhere",
      details: error.message
    }), {
      headers: {
        "Content-Type": "application/json"
      }
    });
  }
});
