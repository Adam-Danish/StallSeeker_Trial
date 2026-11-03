# Connect hello.stallseeker.my

The landing page is prepared in Sites. The custom hostname is registered and awaiting DNS validation. It is currently a private review site; custom DNS does not make it public.

At the DNS provider for `stallseeker.my`, add these records. Names below are fully qualified; providers that append `stallseeker.my` automatically may require only the relative name.

| Type | Name | Value |
| --- | --- | --- |
| CNAME | `hello.stallseeker.my` | `custom-domains.chatgpt.site.` |
| TXT | `_openai-site-verification.hello.stallseeker.my` | `openai-site-verification=ZPZIVQpRyIFPRn2rq8rLW9GgqszgsAfeDkDjB_zTn-w` |
| TXT | `_cf-custom-hostname.hello.stallseeker.my` | `6b6f2f42-5a89-4735-b450-20eda6347740` |

Do not replace records for the root domain, the existing app, email, or other subdomains. If a record for `hello` already exists, review it before changing it.

After the records propagate, refresh domain validation in Sites. HTTPS is issued once validation succeeds. Visitor access is managed separately from DNS; the current review deployment is owner-private.

Current review URL: https://hello-stallseeker.sillycube2.chatgpt.site
