
# Data Issues and Cleansing Rules
Source: LegacyCRM (CUST_MASTER, ORDER_HDR)  |  Target: ModernCRM

## CUST_MASTER (legacy customers)

| Column | Problem found | Cleansing rule |
|---|---|---|
| (table) | No primary key | CUST_NO becomes the primary key in the target |
| CUST_NO | 20 exact duplicate rows | Keep one copy, drop the rest |
| CUST_NO | ~10 customers re-entered under C9xxxx numbers | Merge into the original customer number |
| CUST_NAME | Mixed formats ("Last, First" vs "First Last") | Split into FirstName and LastName |
| CUST_NAME | Extra spaces and ALL CAPS | Trim and convert to proper case |
| CUST_NAME | NULL names | Reject and log to the error table |
| EMAIL | NULL emails | Allow NULL (optional field) |
| EMAIL | Invalid emails (missing @) | Set to NULL and log as a warning |
| PHONE | Mixed formats: (317) 555-..., 317.555..., +1 317-..., digits only | Strip to 10 digits, store as ###-###-#### |
| PHONE | "N/A" and 7-digit numbers with no area code | Set to NULL and log as a warning |
| ST | Mixed values: IN, in, "IN ", Indiana, ind., Illinois | Map to 2-letter uppercase codes |
| ZIP | ZIP+4 (46204-1234) | Keep the first 5 digits |
| ZIP | 4-digit ZIPs (lost leading zero) | Pad with a leading zero, or log if it can't be fixed |
| JOIN_DT | Stored as text in mixed formats | Convert to DATE |
| JOIN_DT | 00/00/0000 (not a real date) | Set to NULL and log as a warning |
| STATUS_CD | Mixed values: A, active, I, blank | Map to ACTIVE / INACTIVE; blank = UNKNOWN |

## ORDER_HDR (legacy orders)

| Column | Problem found | Cleansing rule |
|---|---|---|
| (table) | No primary key | ORD_NO becomes the primary key (checked: no duplicate order numbers) |
| CUST_NO | No foreign key to customers | Add FK to the Customer table in the target |
| CUST_NO | Orphan orders for C99999 (customer doesn't exist) | Reject and log to the error table |
| ORD_DT | Mixed formats (2026-01-15, 01/15/2026, Jan 15, 2026) | Convert to DATE |
| ORD_DT | Blank dates | Reject and log |
| ORD_AMT | Stored as text, some with $ and commas | Strip $ and commas, convert to DECIMAL(10,2) |
| ORD_AMT | "N/A" values | Reject and log |
| ORD_AMT | Negative amounts (-45.00) | Reject and log |
| ORD_STATUS | Mixed case (SHIPPED, shipped) | Convert to uppercase |
| ORD_STATUS | Cancelled written as Cancelled and cncl | Map to CANCELLED |
| ORD_STATUS | Full target list | SHIPPED, CANCELLED, OPEN |

## Checks done
- Duplicate ORD_NO: none found
- Duplicate orders (same customer, date, amount): none found
- The only duplicates are in CUST_MASTER
```

Tell me once it's saved, and we'll create the ModernCRM tables.