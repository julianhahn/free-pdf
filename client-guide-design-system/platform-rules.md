# Rebuilding natively

A client never loads the CSS in `../design/` or the HTML in `../storybook/`. It reads
[tokens.md](./tokens.md) and [components.md](./components.md) and builds the same thing in its
own toolkit - SwiftUI on iPhone, whatever comes next elsewhere. The reason is
recognizability: two FreePDF clients should look like one product, and still feel like the
phone they run on.

## Must be the same everywhere

Because these are what make it recognizable, and they are all written down, so nobody has to
guess.

- the six colour roles and the two ramps, light and dark
- the two faces and which one is heading and which is body, and the size steps
- the spacing steps, the radii, the shadows
- **stroke, not fill**: buttons, rows, the shutter, the switch and the slider are outlined.
  A filled platform-default button is the one thing that breaks the look immediately.
- one accent. No second colour, no red, no green.
- every word, in both languages, exactly as in components.md
- the set of states a component has. If the list says a scan row has seven subtitles, the
  client shows seven, not six.
- numbers use tabular figures, so a counter does not shuffle while it counts

## May differ

Because the platform is better at these than a document is, and forcing them makes the app
feel foreign.

- **gestures** - swipe-to-delete is that platform's swipe, with its own threshold and bounce
- **control mechanics** - a switch is that platform's switch, restyled to the tokens; a slider
  tracks the finger the way the platform tracks it
- **presentation** - a dialog, a sheet, a menu appear the way the platform appears them
- **animation timing and easing** - no numbers are prescribed
- **haptics and sounds** - the platform's, or none
- **layout under pressure** - long German strings, small screens and large text may wrap,
  stack or scroll differently per client

A little drift here is expected and fine.

## The accessibility floor

Holds on every client, no exceptions. These are not style, so the theme does not get to
override them.

- **44 pt minimum touch target**, even where the drawn control is smaller. The switch is 24
  high and the slider thumb 17 - the tappable area around them is still 44.
- **A label on every control**, read out by the screen reader, saying what it does and not
  what it looks like: "Photograph page 7", not "button". The labels in components.md are the
  labels.
- **State is announced, not only drawn.** Disabled, selected, busy and the current page all
  reach the screen reader. A disabled shutter must say it is disabled.
- **Works at large text sizes.** Text scales with the system setting; nothing is clipped and
  no layout is pinned to a fixed height that assumes small text.
- **Light and dark both.** Every colour in tokens.md has both values. Never ship one theme.
- **Focus is visible** - 2 px accent, 2 px offset - for anything a keyboard or switch control
  can reach.
- **Never colour alone.** This is a one-accent theme with no red, so a destructive action is
  carried by its words ("Delete scan", "This cannot be undone"), and an error by its sentence.

Open concern, from [AGENTS.md](./AGENTS.md): the shutter and the destructive button are where
a reading aesthetic meets a thumb in bad light. If a client finds a hairline unusable in the
real world, say so - do not quietly thicken it.
