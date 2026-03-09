# AI Context: Odoo Module Migration (v12 → v19)

**Purpose**: This document provides comprehensive directives for any AI agent to migrate Odoo modules from version 12 to any target version up to 19. Apply ONLY the rules relevant to your source → target version range.

**Usage examples**:
- _"Migra el módulo v12 `/tmp/12/my_module` a la versión 19 y guarda en `/tmp/v19/my_module`"_
  → Copy the source module to `/tmp/v19/my_module`, then apply ALL rules from v12→13 through v18→19 sequentially.
- _"Migra el módulo v12 `my_module` a la versión 18"_
  → Apply rules from v12→13 through v17→18 only. If no output path is given, ask the user where to save the output OR create it alongside the source with a version suffix.
- File types to process: `.py`, `.xml`, `.js`, `.csv`

**Agent behavior**:
- ALWAYS read and understand the full module structure before making changes.
- Preserve the module's directory structure (models/, views/, security/, data/, etc.).
- Apply rules **in version order** (v12→v13 first, then v13→v14, etc.) — do NOT skip versions.
- After completing all transformations, do a final scan for leftover deprecated patterns.

> **CRITICAL (Anti-Hallucination)**: If you encounter code, XML tags, or logic that you **cannot migrate with certainty**, do NOT invent code. Leave the original code (commented if appropriate) and add: `# TODO_AI: [Explanation of what could not be migrated and why]` for human review.

---

## General Rules (Apply Always)

### Manifest File
- Rename `__openerp__.py` → `__manifest__.py` (if still named `__openerp__.py`).
- Set `"installable": True` in the manifest.
- Remove the `migrations/` folder from the module if it exists.
- Update the `version` field to match the target Odoo version (e.g., `"19.0.1.0.0"`).
- Remove `<data noupdate="0">` → replace with `<data>` in XML data files.
- Remove the `string="..."` attribute from `<tree>` / `<list>` tags in XML.

### Python Encoding Headers
- Remove `# -*- encoding: utf-8 -*-` and `# -*- coding: utf-8 -*-` headers (unnecessary since v11+).

---

## v12 → v13 Changes

### Python (.py)

#### Decorators Removed
- **Remove** `@api.multi` (lines containing it should be deleted entirely).
- **Remove** `@api.one` (lines containing it should be deleted entirely).
- **Flag as error** `@api.returns` — deprecated decorator, must be manually reviewed.
- **Flag as error** `@api.cr`, `@api.model_cr`, `@api.model_cr_context` — deprecated decorators.

#### ORM & API Changes
- **Replace** `.sudo(user)` → `.with_user(user)` (when `.sudo()` receives a user argument).
- **Replace** `.suspend_security` → `.sudo`.
- **Remove** the dependency `"base_suspend_security"` from the manifest if present.
- **Replace** `track_visibility="onchange"` or `track_visibility="always"` or any `track_visibility='...'` → `tracking=True`.
- **Replace** `._find_partner_from_emails(` → `._mail_find_partner_from_emails(`.
- **Replace** `._search_on_partner(` → `._mail_search_on_partner(`.
- **Replace** `._search_on_user(` → `._mail_search_on_user(`.
- **Replace** `digits=dp.get_precision(X)` → `digits=X` and remove the `import odoo.addons.decimal_precision` line.
  - Also remove `from odoo.addons import decimal_precision` import lines.

#### Company Context
- **Warning**: Replace `env.user.company_id` → `env.company` when the intention is to get the current active company.

#### Deprecated Modules (v12→v13)
Check the manifest `depends` list. Key changes:
| Old Module | Action | New Module |
|---|---|---|
| `web_settings_dashboard` | removed | — |
| `account_asset` | moved to OCA | `account_asset_management` |
| `account_budget` | removed | — |
| `account_invoicing` | merged | `account` |
| `auth_crypt` | merged | `base` |
| `base_vat_autocomplete` | renamed | `partner_autocomplete` |
| `sale_order_dates` | merged | `sale` |
| `sale_payment` | merged | `sale` |
| `web_planner` | merged | `web` |

### XML (.xml)

#### Actions & Views
- **Remove** `<field name="view_type">...</field>` from action definitions.
- **Replace** `src_model` → `binding_model` in action attributes.

#### Boolean Button Widget → Web Ribbon
Replace the old `oe_stat_button` with `boolean_button` widget pattern:
```xml
<!-- OLD (v12) -->
<button class="oe_stat_button" ...>
    <field name="active" widget="boolean_button" .../>
</button>

<!-- NEW (v13+) -->
<field name="active" invisible="1" />
<widget name="web_ribbon" title="Archived" bg_color="bg-danger"
    attrs="{'invisible': [('active', '=', True)]}" />
```
> **Note**: The `attrs` in this v13 example will be converted to `invisible="active"` when applying the v17 attrs→inline rule later.

---

## v13 → v14 Changes

### XML (.xml)

#### Deprecated Tags: `<act_window>` and `<report>`
These shortcut tags are removed. Convert them to `<record>` tags:

```xml
<!-- OLD: <act_window id="action_id" name="Action" res_model="model.name" view_mode="tree,form" /> -->
<!-- NEW: -->
<record id="action_id" model="ir.actions.act_window">
    <field name="name">Action</field>
    <field name="res_model">model.name</field>
    <field name="view_mode">tree,form</field>
</record>
```

For `<report>` tags, note the attribute renames:
- `string` → `name` (field)
- `name` → `report_name` (field)
- `src_model` → `binding_model_id` with `ref="module.model_model_name"` format.

#### Binding Model Format
Replace `src_model="model.name"` with a proper field reference:
```xml
<!-- OLD -->
<field name="binding_model">account.move</field>

<!-- NEW -->
<field name="binding_model_id" ref="account.model_account_move"/>
```

### JavaScript (.js)
- **Replace** `tour.STEPS.SHOW_APPS_MENU_ITEM` → `tour.stepUtils.showAppsMenuItem()`.
- **Replace** `tour.STEPS.TOGGLE_HOME_MENU` → `tour.stepUtils.toggleHomeMenu()`.

### Python (.py) (Tests)
- **Replace** `.phantom_js(` → `.browser_js(` in test files.

### Removed Fields (v13→v14)
| Model | Field | Note |
|---|---|---|
| `mail.template` | `user_signature` | Removed |

### Renamed Fields (v13→v14)
| Model | Old Field | New Field |
|---|---|---|
| `account.move` | `type` | `move_type` |
| `account.move` | `invoice_payment_state` | `payment_state` |
| `account.move` | `invoice_sent` | `is_move_sent` |

---

## v14 → v15 Changes

### Renamed Models (v14→v15)
| Old Model | New Model |
|---|---|
| `sale.commission.settlement` | `commission.settlement` |
| `sale.commission.analysis.report` | `invoice.commission.analysis.report` |
| `sale.commision.make.settle` | `commission.make.settle` |

### XML (.xml)
- **Replace** `widget="toggle_button"` → `widget="boolean_toggle"` in all XML files (applies from v15 onwards).

---

## v15 → v16 Changes

### Python (.py)

#### ORM Method Replacements
- **Replace** `.get_xml_id(` → `.get_external_id(`.
- **Replace** `.fields_get_keys()` → `._fields`.

#### Cache Management (Deprecated Methods)
These methods are deprecated — replace with granular alternatives:
| Old Method | Replacement |
|---|---|
| `flush()` | `flush_model()`, `flush_recordset()`, or `env.flush_all()` |
| `recompute()` | `flush_model()`, `flush_recordset()`, or `env.flush_all()` |
| `refresh()` | `invalidate_model()`, `invalidate_recordset()`, or `env.invalidate_all()` |
| `invalidate_cache()` | `invalidate_model()`, `invalidate_recordset()`, or `env.invalidate_all()` |
| `_invalidate_cache()` | Use the public equivalents above |

#### Name Search
- **Warning**: If overriding `_name_search`, consider using the new `_rec_names_search` class variable instead of a full method override.

### Renamed Models (v15→v16)
| Old Model | New Model |
|---|---|
| `stock.production.lot` | `stock.lot` |

### Removed Models (v15→v16)
| Model | Note |
|---|---|
| `account.account.type` | Removed entirely |

### Renamed Fields (v15→v16)
| Model | Old Field | New Field |
|---|---|---|
| `account.account` | `user_type_id` | `account_type` |
| `account.account` | `internal_type` | `account_type` |
| `account.move.line` | `analytic_account_id` | `analytic_distribution` |
| `stock.move.line` | `product_qty` | `reserved_qty` |
| `hr.expense` | `analytic_account_id` | `analytic_distribution` |

### Removed Fields (v15→v16)
| Model | Field |
|---|---|
| `account.move.line` | `exclude_from_invoice_tab` |
| `product.product` | `price` |

---

## v16 → v17 Changes

### Python (.py)

#### `read_group` → `_read_group` (Major Refactor)
The public `read_group` method is replaced by the private `_read_group` with significant signature changes:

1. **Rename** `.read_group(` → `._read_group(` (except when calling `super()`).
2. **Swap argument order**: `groupby` and `fields` positions are inverted. Old: `_read_group(domain, fields, groupby, ...)` → New: `_read_group(domain, groupby, aggregates, ...)`.
3. **Rename keyword**: `fields=` → `aggregates=`, `orderby=` → `order=`.
4. **Remove** the `lazy` parameter/argument entirely.
5. **Update aggregate format**: Field specs change from old format to `"field_name:agg_function"` notation:
   - `"field:sum"` stays as `"field:sum"`
   - `"id:count"` or `"id:count_distinct"` → `"__count"`
   - Plain field names (no `:`) become `"field:sum"` by default
   - Format `"func(field):func"` → `"field:func"`

#### `message_post_with_view` Removed
- **Replace** `.message_post_with_view(` → `.message_post_with_source(`.

#### Removed Models (v16→v17)
| Model | Note |
|---|---|
| `account.account.template` | Removed |
| `account.tax.template` | Removed |
| `account.group.template` | Removed |

### Renamed Fields (v16→v17)
| Model | Old Field | New Field |
|---|---|---|
| `hr.expense` | `total_amount` | `total_amount_currency` |
| `hr.expense` | `unit_amount` | `price_unit` |
| `hr.expense` | `amount_tax` | `tax_amount_currency` |
| `hr.expense` | `untaxed_amount` | `untaxed_amount_currency` |
| `hr.expense` | `total_amount_company` | `total_amount` |
| `hr.expense` | `sheet_is_editable` | `is_editable` |
| `hr.expense` | `attachment_number` | `nb_attachment` |
| `hr.employee` | `address_home_id` | `work_contact_id` |
| `account.tax` | `l10n_mx_tax_type` | `l10n_mx_factor_type` |

### Removed Fields (v16→v17)
| Model | Field |
|---|---|
| `hr.expense` | `reference` |

### XML (.xml) — `attrs` to Inline Python Expressions

The old `attrs="{'invisible': [('field', '=', value)]}"` dictionary syntax is **removed**. Convert to **inline Python expressions** directly on the attribute:

```xml
<!-- OLD (v12-v16) -->
<field name="x" attrs="{'invisible': [('state', '=', 'draft')]}" />
<field name="y" attrs="{'required': [('type', '!=', 'service')], 'readonly': [('active', '=', False)]}" />

<!-- NEW (v17+) -->
<field name="x" invisible="state == 'draft'" />
<field name="y" required="type != 'service'" readonly="not active" />
```

**Domain-to-Python conversion rules**:
- `('field', '=', value)` → `field == value`
- `('field', '!=', value)` → `field != value`
- `('field', '=', True)` → `field`
- `('field', '=', False)` → `not field`
- `('field', '!=', False)` → `field`
- `('field', '=', [])` → `not field`
- `('field', '!=', [])` → `field`
- `'&'` operator → `and`
- `'|'` operator → `or`
- `'!'` operator → `not (...)`

#### Button `get_formview_action` → `open_form_view`
- **Warning**: Buttons with `name="get_formview_action"` to open form views from tree/list views should be replaced by setting `open_form_view="True"` on the parent tree/list view definition.

### Web Assets
- **Warning**: The bundle `web.assets_common` has been removed. References must be updated to the appropriate new bundle.

---

## v17 → v18 Changes

### XML (.xml)

#### `<tree>` → `<list>` (Comprehensive Rename)
All occurrences of `tree` in the view context must be replaced with `list`:

| Context | Old | New |
|---|---|---|
| XML tags | `<tree>`, `</tree>` | `<list>`, `</list>` |
| View mode field | `<field name="view_mode">tree,form</field>` | `<field name="view_mode">list,form</field>` |
| XPath expressions | `expr="//tree"` | `expr="//list"` |
| Context references | `tree_view_ref` | `list_view_ref` |
| Mode attribute | `mode="tree"` | `mode="list"` |
| String references | `"tree view"` / `"Tree View"` | `"list view"` / `"List View"` |
| `env.ref()` calls | `self.env.ref('...tree')` | `self.env.ref('...list')` |
| `view_mode` in Python | `view_mode="tree"` | `view_mode="list"` |
| `binding_view_types` | `tree` | `list` |

#### Chatter Block → `<chatter/>` Component
Replace the old chatter div pattern with the new component tag:

```xml
<!-- OLD (v12-v17) -->
<div class="oe_chatter">
    <field name="message_follower_ids"/>
    <field name="activity_ids"/>
    <field name="message_ids"/>
</div>

<!-- NEW (v18+) -->
<chatter/>
```

Also update XPath expressions:
- `//div[hasclass('oe_chatter')]` → `//chatter`

If the chatter div has a `position` attribute (in inherited views), preserve it:
```xml
<!-- OLD -->
<div class="oe_chatter" position="before"/>
<!-- NEW -->
<chatter position="before"/>
```

#### Kanban CSS Class Renames
| Old Class | New Class |
|---|---|
| `kanban-card` | `card` |
| `kanban-box` | `card` |
| `kanban-menu` | `menu` |

#### Invisible Fields (Implicit Availability)
- **Warning**: Fields referenced in `invisible="..."`, `readonly="..."`, `required="..."`, `context`, or `domain` attributes are now automatically added to the view. You can remove `<field name="field_x" invisible="1"/>` tags that were only present to support `attrs` logic. Also consider removing `column_invisible="1"` patterns.

#### Cron Jobs (`ir.cron`)
- **Remove** the fields `numbercall` and `doall` from `<record model="ir.cron">` definitions — they have been removed.

### Python (.py)

#### `user_has_groups` Replacement
- **Replace** `self.user_has_groups('single.group')` → `self.env.user.has_group('single.group')`.
- **Replace** `self.user_has_groups('group1,group2')` (multiple/negated) → `self.env.user.has_groups('group1,group2')`.

#### `unaccent` Parameter Removed
- **Remove** `unaccent=True` or `unaccent=False` from `fields.Char()`, `fields.Text()`, `fields.Html()`, `fields.Properties()` declarations.

#### `ustr` Function Removed
- **Remove** imports: `from odoo.tools import ustr`, `from odoo.tools.misc import ustr`.
- **Remove** usage: `ustr(value)` → just use `value` directly (or `str(value)` if conversion needed).
- **Remove** `tools.ustr(...)` and `misc.ustr(...)` calls.

#### Related Fields `store=True`
- **Warning**: It is no longer necessary to set `store=True` on `related=...` fields just for grouping, aggregating, or sorting. Remove `store=True` unless strictly needed for performance.

#### `_name_search` → `_search_display_name`
- **Error**: The method `_name_search` is deprecated. Replace with `_search_display_name`.

#### `setUpClass` — `chart_template_ref` Removed
- **Error**: The `chart_template_ref` parameter has been removed from `setUpClass()` calls in test classes.

#### Registry Import Change
- **Replace** `from odoo import registry` or `odoo.registry(db_name)` → `from odoo.modules.registry import Registry` and use `Registry(db_name)`.

### Renamed Fields (v17→v18)
| Model | Old Field | New Field |
|---|---|---|
| `res.company` | `period_lock_date` | `sale_lock_date` / `purchase_lock_date` |
| `account.move` | `reversal_move_id` | `reversal_move_ids` |

---

## v18 → v19 Changes

### Python (.py)

#### `odoo.osv.expression` → `odoo.fields.Domain`
Migrate all expression usage:
```python
# OLD (v12-v18)
from odoo.osv import expression
domain = expression.AND([domain1, domain2])
domain = expression.OR([domain1, domain2])

# NEW (v19)
from odoo.fields import Domain
domain = Domain.AND([domain1, domain2])
domain = Domain.OR([domain1, domain2])
```

Also handle standalone imports:
- `from odoo.osv.expression import AND` → `from odoo.fields import Domain` (then use `Domain.AND`)
- `from odoo.osv.expression import OR` → `from odoo.fields import Domain` (then use `Domain.OR`)

#### `_sql_constraints` → `models.Constraint`
Replace the class-level list with individual class attributes:
```python
# OLD (v12-v18)
_sql_constraints = [
    ('name_uniq', 'unique(name)', 'The name must be unique!'),
    ('check_amount', 'CHECK(amount > 0)', 'Amount must be positive.'),
]

# NEW (v19)
_name_uniq = models.Constraint(
    'unique(name)',
    "The name must be unique!",
)
_check_amount = models.Constraint(
    'CHECK(amount > 0)',
    "Amount must be positive.",
)
```

#### Controller Route Type Rename
- **Replace** `type='json'` → `type='jsonrpc'` and `type="json"` → `type="jsonrpc"` in controller `@http.route()` decorators.

#### Deprecated Private Properties
- **Replace** `._cr` → `.env.cr`
- **Replace** `._uid` → `.env.uid`
- **Replace** `._context` → `.env.context`

#### Field Parameter Rename
- **Replace** `auto_join=` → `bypass_search_access=` in relational field declarations.

#### `groups_id` → `group_ids`
- In XML: Replace `name="groups_id"` → `name="group_ids"` in `<field>` tags.
- In Python: Replace `.groups_id` / `"groups_id"` / `'groups_id'` → `.group_ids` / `"group_ids"` / `'group_ids'`.

#### `ormcache_context` Deprecated
- **Replace** `@tools.ormcache_context(...)` → `@tools.ormcache(...)` and access context values within the method body via `self.env.context.get(...)`.

#### Environment is Read-Only
- **Warning**: The `Environment` (`env`) is now strictly read-only. Avoid assigning attributes like `self.env.field = value`. Use `with_context()`, `with_user()`, or `with_company()` instead.

#### Timezone Handling
- **Replace** manual timezone handling:
  - `pytz.timezone(self.env.context.get('tz'))` → `self.env.tz`
  - `pytz.timezone(self.env.user.tz)` → `self.env.tz`
  - `self.env.tz` provides automatic fallback: context → user → UTC.

#### URL Joining Functions
- **Replace** `url_join(...)` / `urljoin(...)` → `odoo.tools.urls.urljoin(...)` for explicit and safer URL joining.

### XML (.xml)

#### Search Views: Remove `expand` and `string` from `<group>`
- **Remove** `expand="..."` and `string="..."` attributes from `<group>` tags inside `<search>` views.

---

## Deprecated Modules Reference (Cumulative v12→v19)

When migrating, verify the module's `depends` list. Below is a summary of key module changes. If a dependency references a deprecated/renamed/merged module, update accordingly:

### Modules Removed (No Replacement)
`web_settings_dashboard`, `account_budget`, `anonymization`, `mrp_repair`, `pos_data_drinks`, `product_extended`, `rating_project`, `report_intrastat`, `website_forum_doc`, `website_rating_project`, `website_sale_options`, `website_sale_stock_options`, `l10n_be_intrastat`, `l10n_be_intrastat_2019`

### Modules Merged Into Another
| Old Module | Merged Into |
|---|---|
| `account_cash_basis_base_account` | `account` |
| `account_invoicing` | `account` |
| `auth_crypt` | `base` |
| `sale_order_dates` | `sale` |
| `sale_payment` | `sale` |
| `sale_service_rating` | `sale_timesheet` |
| `web_planner` | `web` |

### Modules Renamed
| Old Module | New Module |
|---|---|
| `base_vat_autocomplete` | `partner_autocomplete` |
| `stock_picking_wave` | `stock_picking_batch` |
| `base_action_rule` | `base_automation` |

### Modules Moved to OCA
| Old Module | New Module | OCA Repository |
|---|---|---|
| `account_asset` | `account_asset_management` | OCA/account-financial-tools |
| `hr_timesheet_sheet` | `hr_timesheet_sheet` | OCA/hr-timesheet |

---

## Migration Workflow for AI Agent

Follow this step-by-step workflow when performing a migration:

### Step 1: Setup
1. If the user specifies an output path, copy the source module directory to that location. If not specified, ask the user or create the output alongside the source.
2. **Read ALL files** in the module to understand the full structure before making changes.
3. Identify the source and target versions from the user's request.
4. Determine which version-step rules apply (e.g., v12→v19 means ALL rules apply).

### Step 2: Manifest (`__manifest__.py`)
1. Rename `__openerp__.py` → `__manifest__.py` if needed.
2. Update the `version` field to target version format.
3. Check and update `depends` against the deprecated modules lists.
4. Remove references to removed/deprecated modules.
5. Set `"installable": True`.

### Step 3: Python Files (`.py`)
1. Remove deprecated decorators (`@api.multi`, `@api.one`, etc.).
2. Apply all ORM method replacements (version by version).
3. Update imports (`expression` → `Domain`, `registry`, `ustr`, `dp`, etc.).
4. Rename fields/models in Python code.
5. Convert `_sql_constraints` to `models.Constraint` (v19).
6. Update controller routes (`type='json'` → `type='jsonrpc'`) (v19).
7. Replace deprecated property access (`._cr`, `._uid`, `._context`).
8. Update `read_group` calls to `_read_group` with new signature (v17).

### Step 4: XML Files (`.xml`)
1. Convert `<act_window>` and `<report>` tags to `<record>` (v14).
2. Remove `<field name="view_type">` from actions (v13).
3. Convert `attrs` dictionaries to inline Python expressions (v17).
4. Replace `<tree>` → `<list>` everywhere (v18).
5. Replace chatter `<div class="oe_chatter">` → `<chatter/>` (v18).
6. Rename kanban CSS classes (v18).
7. Remove `numbercall`/`doall` from cron definitions (v18).
8. Clean up search view `<group>` attributes (v19).
9. Rename `groups_id` → `group_ids` (v19).
10. Remove `string="..."` attribute from list view definitions.

### Step 5: JavaScript Files (`.js`)
1. Update tour step references (v14).
2. Apply tree→list renames in JS (v18).

### Step 6: Remove Obsolete Artifacts
1. Delete the `migrations/` folder if it exists.
2. Remove Python 2 encoding headers.

### Step 7: Verification
1. Check that all imports resolve correctly.
2. Verify no deprecated patterns remain (search for known deprecated patterns).
3. Ensure XML is well-formed.
4. Flag any `TODO_AI` comments for human review.

---

## Quick Reference: Version-Specific Rule Summary

| Version | Key Changes |
|---|---|
| **v13** | Remove `@api.multi`/`@api.one`; `sudo(user)`→`with_user(user)`; `track_visibility`→`tracking=True`; `env.company` |
| **v14** | `<act_window>`/`<report>` → `<record>`; `phantom_js`→`browser_js`; tour steps update |
| **v15** | `toggle_button`→`boolean_toggle`; commission model renames |
| **v16** | `flush()`/`invalidate_cache()` deprecated; `stock.production.lot`→`stock.lot`; `account.account.type` removed; `_rec_names_search` |
| **v17** | `read_group`→`_read_group` refactor; `attrs`→inline expressions; `message_post_with_view`→`message_post_with_source`; `web.assets_common` removed |
| **v18** | `<tree>`→`<list>`; `<chatter/>`; kanban classes; `user_has_groups`; `unaccent` removed; `ustr` removed; `_name_search`→`_search_display_name`; `Registry` import; `related store=True` cleanup |
| **v19** | `expression`→`Domain`; `_sql_constraints`→`models.Constraint`; `type='json'`→`type='jsonrpc'`; `._cr`→`.env.cr`; `auto_join`→`bypass_search_access`; `groups_id`→`group_ids`; `ormcache_context` deprecated; `self.env.tz`; `tools.urls.urljoin` |
