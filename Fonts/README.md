# Fonts Directory

## Adding Albra Book Light Font

To use the Albra Book Light font in your app:

1. **Download the font file** (e.g., `AlbraBookLight.otf` or `AlbraBookLight.ttf`)
2. **Place it in this Fonts folder**
3. **Add it to your Xcode project**:
   - Drag the font file into Xcode
   - Make sure "Add to target" is checked for your main app target
   - Ensure "Copy items if needed" is selected

## Font File Requirements

- **Format**: .otf, .ttf, or .ttc
- **Name**: Must match exactly what you use in `.custom("Albra Book Light", size:)`
- **Target**: Must be added to your main app target

## Common Font Names

The font name in code should match the PostScript name of the font file:
- Try: "Albra Book Light"
- Or: "AlbraBookLight" 
- Or: "Albra-BookLight"

You can check the exact font name by:
1. Double-clicking the font file in Finder
2. Looking at the font preview window title
3. Using Font Book app to inspect the font details
