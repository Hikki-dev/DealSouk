# Questions and answers

**Is this a real supermarket app?**
It is a working project built around real Dubai supermarket chains. The prices in the demo are made-up sample data, and DealSouk does not sell groceries or take orders.

**Can I try it without accounts?**
Yes. See [Demo mode](Demo%20mode.md). It needs Flutter, Node and a Postgres.

**How does it know a price is real?**
A moderator checks each price against the photo before it counts. Shoppers can also flag a price, and three different flags hide it. Every shopper has an accuracy score, and moderators can warn, suspend or ban someone who shares wrong prices.

**How long does a price count?**
72 hours. After that it is dimmed and no longer used for the best price.

**What are tokens for?**
Sharing a price earns tokens (50 by default). With 500 tokens a shopper can ask for a supermarket voucher. Tokens are also the bounty on price requests.

**Can someone cheat the tokens?**
The ledger is hash-chained, so a changed row can be found. There is a daily limit, duplicates are worth less, and only moderator-approved prices earn. Accounts that sign in only with a password must verify their email before they can earn.

**Which languages?**
English and Arabic, including right-to-left layout.

**Where does the data live?**
In Postgres (Neon in production). Phone numbers are encrypted at rest. Photos go to Firebase Storage.

**Why is the admin the same code as the shopper app?**
One Flutter code base builds both. `--dart-define=ADMIN_MODE=true` builds the moderator portal, so the two share the same network code, theme and widgets.

**Can I use the code?**
There is no licence file yet, so all rights are reserved for now. Ask first.
