import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const MIDTRANS_SERVER_KEY = Deno.env.get("MIDTRANS_SERVER_KEY") || ""
const SNAP_URL = "https://app.sandbox.midtrans.com/snap/v1/transactions"

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    })
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    })
  }

  try {
    const body = await req.json()
    const {
      orderId,
      amount,
      planName,
      customerName = "Petani Maju",
      customerEmail = "customer@petanimaju.id",
      paymentMethod = "qris",
    } = body

    // Validate input
    if (!orderId || !amount) {
      return new Response(
        JSON.stringify({ error: "Missing orderId or amount" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      )
    }

    if (!MIDTRANS_SERVER_KEY) {
      return new Response(
        JSON.stringify({ error: "Server key not configured" }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      )
    }

    const cleanItemName = (`PRO ${planName}`)
      .replace(/[^\w\s\-]/g, "")
      .trim()
      .substring(0, 45)

    const payload = {
      transaction_details: {
        order_id: orderId,
        gross_amount: amount,
      },
      customer_details: {
        first_name:
          customerName && customerName.trim() ? customerName : "Petani",
        email:
          customerEmail && customerEmail.trim()
            ? customerEmail
            : "customer@petanimaju.id",
      },
      item_details: [
        {
          id: `PRO-${planName.replace(/\s+/g, "-").toUpperCase()}`,
          price: amount,
          quantity: 1,
          name: cleanItemName,
        },
      ],
      enabled_payments: [paymentMethod],
    }

    // Create Basic Auth header
    const auth = btoa(`${MIDTRANS_SERVER_KEY}:`)

    console.log(`[Midtrans Edge Function] Creating transaction: ${orderId}`)

    const response = await fetch(SNAP_URL, {
      method: "POST",
      headers: {
        Authorization: `Basic ${auth}`,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify(payload),
    })

    const data = await response.json()

    if (!response.ok) {
      console.error(`[Midtrans Edge Function] Error: ${response.status}`, data)
      return new Response(JSON.stringify({ error: data }), {
        status: response.status,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      })
    }

    console.log(`[Midtrans Edge Function] Success: ${orderId}`)

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    })
  } catch (error) {
    console.error("[Midtrans Edge Function] Exception:", error)
    return new Response(
      JSON.stringify({ error: `Server error: ${error.message}` }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    )
  }
})
