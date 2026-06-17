# Skill Manual: USSD Integration

Guidelines for building lightweight, responsive USSD menus for smallholder farmers.

---

## 🎯 Purpose
To provide a fail-proof, low-cost microfinance interface operating on basic feature phones. Farmers can register, view balances, apply for loans, and check harvest deliveries without internet access.

---

## 💡 Best Practices

* **State-Machine Architecture:** Model the USSD navigation as a strict state machine. Save session states (like `CURRENT_MENU`, `FARMER_ID`, `SELECTED_LOAN_AMOUNT`) in a fast cache (Redis) or PostgreSQL database indexed by `SessionId`.
* **Sub-160 Character Limit:** Keep all USSD screen messages short. Break menus into multiple screens if content exceeds 160 characters to prevent carrier splitting bugs.
* **Dialect Localization:** Support simple language options on the landing screen (1: English, 2: Twi, 3: Fante). Save selection to the session profile.
* **Quick Navigation Shortcuts:** Allow users to use quick numbers (e.g. `0` to return to Main Menu, `9` to go Back).

---

## 🛑 Constraints

* **Fast Response Timeout:** USSD gateways (like Africa's Talking) drop sessions if the webhook server takes longer than 3-5 seconds to reply. All background blockchain transactions must run asynchronously after the USSD screen displays confirmation.
* **No Free-Text Fields:** Avoid asking farmers to type complex text. Use multiple-choice selectors. The only exceptions are numeric fields (e.g. Mobile Money number or weight details).

---

## 📐 Code Conventions

* **Standard USSD Request Response Format:**
  * Request payload (from gateway): `sessionId`, `phoneNumber`, `text`, `serviceCode`.
  * Response prefix:
    * `CON ` (Continue - shows input field/menu)
    * `END ` (End - shows final message and terminates call)
* **Session Handler Example:**
  ```typescript
  // Typical Express endpoint handler for USSD
  app.post('/api/v1/ussd', async (req, res) => {
    const { sessionId, phoneNumber, text } = req.body;
    let response = "";
    
    const session = await getOrCreateUssdSession(sessionId, phoneNumber);
    const parsedInput = text.split('*').pop(); // Get latest user selection
    
    // Process input through session state machine
    const { nextState, screenText } = processUssdState(session, parsedInput);
    
    await updateUssdSession(sessionId, { state: nextState });
    
    res.set('Content-Type', 'text/plain');
    res.send(screenText); // Should start with CON or END
  });
  ```

---

## ⚠️ Common Pitfalls

* **Database Block Delay:** Making blocking queries to external blockchain RPCs inside the USSD response loop. Always reply with `END Your transaction is processing...` and handle execution in a queue.
* **Session Mismatch:** Overwriting session data if a farmer redials too fast before the previous session times out in the gateway.

---

## ✅ Acceptance Criteria

1. **Gateway Compliance:** Responses format string prefixes (`CON` or `END`) correctly.
2. **Dialect Integrity:** Switch logic successfully routes English, Twi, and Fante copy blocks.
3. **Recovery:** Dropped calls recover the previous state when dialled back within 2 minutes.
