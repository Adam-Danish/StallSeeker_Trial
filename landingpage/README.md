# StallSeeker landing page

A responsive landing page prepared for **hello.stallseeker.my**, using the existing StallSeeker logo and actual app screenshots. No generated photos or illustrations are included.

The visual direction follows the supplied no-ai-slop rules: Archivo display typography, Newsreader body typography, white surfaces, high-contrast text, restrained orange accents, small corner radii, and an asymmetric layout. The reference website informed the inclusion of project background and scope information. Its copy, branding, and layout are not reused.

## Preview

Run `npm run dev` (Node.js is the only requirement), then open http://127.0.0.1:4173. No installation or build step is needed. You can also open `dist/index.html` directly.

## Edit

- `dist/index.html`: page content and app links.
- `dist/styles.css`: layout, colours, and mobile styles.
- `dist/app.js`: navigation, feature preview tabs, and footer year.
- `dist/assets/`: existing project branding and images.

All app buttons open **https://stallseeker.my**, as requested. The page explains that StallSeeker is an FYP mobile app which has not yet been published, with the web version available first for iPhone and Android browsers. The page does not collect visitor data, submit bookings itself, or advertise an App Store release.

The existing project screenshots illustrate app behaviour. Vendor updates determine actual location and food availability.

## Hosting

Upload the contents of `dist` to a static website host. The Sites publishing checkout is maintained separately from the parent Flutter repository so publishing the landing page does not include the app's source or credentials.

Connecting `hello.stallseeker.my` requires DNS changes at the domain provider. A local folder or a successful preview alone does not connect the domain.

Typography uses Inter throughout, following the user preference. The supplied no-ai-slop rules inform the white surfaces, high-contrast text, small corner radii, and restrained orange accents.

