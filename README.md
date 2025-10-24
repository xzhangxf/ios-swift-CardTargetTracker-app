//README.md//
for now
Root: Tab Bar Controller with four tabs → Home / Daily / Categories / Settings.

Home tab

Home List → Card Detail (push, tap card)

Card Detail → Add Transaction (modal)

Card Detail → Edit Card (modal)

Card Detail → Transaction Detail (push)

Add Transaction → Save → Card Detail (update)

Edit Card → Save → Home List (update)

Transaction Detail → Edit → Add Transaction (prefilled)

Daily tab

Daily Overview → Day Detail (push, tap date)

Day Detail → Transaction Detail (push)

Transaction Detail → Open Card Detail (push or modal)

Categories tab

Categories Overview → Category Detail (push, tap category)

Category Detail → Transaction Detail (push)

Transaction Detail → Card Detail (push or modal)

Settings tab

Settings Main → Notifications Section (inline panel)

Settings Main → Data Section → Export Data (share sheet modal) / Clear Data (alert)

Settings Main → About and Privacy Page (push)

Global flows

First Launch → Onboarding → Empty Home

Add Card Success → Home

Add Transaction Success → Card Detail

Cycle Completion → Home or Report Screen

Connector legend:

Blue arrow = push navigation

Gray arrow = modal presentation

Red arrow = destructive action (delete or clear)


As HIG and App Store review

apple generally recommends onboarding only when absolutely necessary
According to the Human Interface Guidelines (HIG):

“Avoid onboarding unless it adds real value.
People want to start using your app immediately, not learn about it.”

so if the app If your app is self-explanatory and has a clear empty state (like “Add your first card to get started”), you don’t need a separate onboarding flow.

If your app requires permissions (camera, location, notifications), onboarding is useful to explain why before the system prompt appears.

