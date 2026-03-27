## 2.1.0

- **3D edge support:** Cards now show a 3D edge effect during the flip. New `show3DEdge` parameter (and related options) let you tune the look.
- **Deeper perspective:** Increased the default depth perspective transform for a more pronounced 3D feel.
- **Curve fixes:** Refined animation curves for smoother, more natural flip transitions.
- **Removed card collection animation:** Simplified the API by dropping the card-collection entrance animation.
- **Animation rewrite and hardening:** Internally rewrote and optimised the animation logic; improved reliability when flips are interrupted or rapidly triggered.

## 2.0.0

Animation, gestures, and reliability:

- **Smoother timing:** The main flip uses ease-in-out. After the halfway point, completion runs with a linear curve so the end of the rotation does not feel doubly eased. New **`completionPhaseScale`** (default **1.35**) stretches the second half of the flip; default **`animationDuration`** is **1000 ms**. How long completion takes scales with how much of the flip is left and how fast you flicked, clamped between **100 ms** and **6000 ms**. Keyboard-triggered flips use a straight `forward()` on the controller.
- **Less jumpiness mid-flip:** Vertical correction after the midpoint eases in over a short window instead of jumping in one step. The blend ramp is wider so auto-complete feels steadier.
- **Lifting your finger always finishes or cancels the flip:** Past the visual halfway point, or past **`thresholdValue`** before halfway → the flip completes. Otherwise → it springs back to the start. You no longer get stuck after release just because an internal animation guard was active.
- **Releases between threshold and halfway still complete:** If you let go past **`thresholdValue`** but before the visual halfway point, the animation still runs to the end. The deck order still updates when the animation crosses the true halfway point. Completion is scheduled immediately (not deferred in a microtask) so the deck does not sit half-committed with flags set and nothing moving.
- **Recovery when the second half does not start:** A short watchdog (~72 ms) retries starting completion if it never attaches. Internal flags clear when a flip finishes or when **`cardData`** changes; completion gates reset if scheduling fails.
- **Stable card widgets:** The top card’s widget is reused when it moves behind the stack so keys and state stay consistent. **`cardBuilder`** docs recommend **`ValueKey`** (or similar) on your data **`index`** or another stable id-not only on **`visibleIndex`**.
- **Bugfix:** Removed a debounce path that could mark the card as switched without actually reordering the list.
- **Documentation:** Class-level notes on how main easing and completion animations work together.

## 1.0.0

- **First stable release**  
  Introduced a polished and reliable swipeable card flipping solution:
  - Smooth flipping animations with refined transitions.
  - Enhanced customization options for scaling, offsets, and card reordering.
  - Better performance and stability.

## 0.0.1

- **Initial Release:**  
  Debut of the Flip Card Swiper with:
  - Vertical flipping animations for a deck of cards.
  - Mid-animation card reorder for continuous looping.
  - Basic customization of scale and offsets.
  - Integrated haptic feedback to enhance user interaction.

  Compatible with Android and iOS, enabling in-app gesture-driven navigation through card sets.
