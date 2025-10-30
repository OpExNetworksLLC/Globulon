# Guide: Comparing Working vs Non-Working Projects

## Systematic Comparison Approach

### 1. **Key Files to Compare**

#### Project Configuration Files:
- `Info.plist` - App configuration, permissions, URL schemes
- `*.entitlements` - Capabilities (push notifications, background modes, etc.)
- `project.pbxproj` (Xcode project file) - Build settings, targets, dependencies
- `Package.swift` or `Podfile` or `Cartfile` - Dependencies

#### App Entry Points:
- `AppDelegate.swift` / `SceneDelegate.swift`
- Main app file (e.g., `GlobulonApp.swift`)
- `LaunchScreen.storyboard`

#### Critical Configuration:
- Build Settings in Xcode:
  - Compiler flags (e.g., `FIREBASE_ENABLED`, `KEYCHAIN_ENABLED`)
  - iOS Deployment Target
  - Signing & Capabilities
  - Info.plist settings

### 2. **Tools for Comparison**

#### Command Line Tools:

```bash
# Compare entire project directories (overview)
diff -rq /path/to/working-project /path/to/not-working-project

# Compare specific files
diff /path/to/working-project/AppDelegate.swift /path/to/not-working-project/AppDelegate.swift

# Find files that differ
diff -rq --exclude=".git" --exclude="DerivedData" \
    /path/to/working-project /path/to/not-working-project | grep "differ"

# Compare Info.plist (can be in different formats)
# Use plutil to convert to XML format first:
plutil -convert xml1 -o - Info.plist | diff - /path/to/other/Info.plist
```

#### Xcode Comparison:
- Right-click file → "Open with External Editor" → Compare
- Use Xcode's File Compare feature (Option-click + Compare)
- Use Source Control → Compare versions

#### Using `diff` with unified context:
```bash
diff -u /path/to/working/File.swift /path/to/not-working/File.swift > diff_output.txt
```

### 3. **Step-by-Step Comparison Process**

1. **Start with Configuration:**
   - Open both projects in Xcode
   - Compare Build Settings side-by-side
   - Check all targets match

2. **Compare Entitlements:**
   ```bash
   # In Terminal, compare entitlements
   diff working-project/ naming.entitlements not-working-project/ naming.entitlements
   ```

3. **Compare Info.plist:**
   - Check for missing keys
   - Compare permission descriptions
   - Verify URL schemes, bundle identifiers

4. **Compare Dependencies:**
   - Check Swift Package Manager dependencies
   - Compare versions of external libraries
   - Verify all dependencies are properly linked

5. **Code Comparison:**
   - Start with entry points (`AppDelegate`, main app file)
   - Compare initialization sequences
   - Check for missing delegate assignments

6. **Build Settings Deep Dive:**
   - Compiler flags (may affect conditional compilation)
   - Swift version
   - Optimization settings
   - Code signing

### 4. **Common Issues to Check**

#### Missing or Different:
- [ ] Delegate assignments (`@UIApplicationDelegateAdaptor`)
- [ ] Scene configuration
- [ ] Background modes in entitlements
- [ ] Info.plist keys (especially permission descriptions)
- [ ] Build flags affecting conditional compilation (`#if FIREBASE_ENABLED`)
- [ ] Frameworks/imports
- [ ] Initialization order in `init()` or `didFinishLaunching`

#### Different but Present:
- [ ] Compiler flag values
- [ ] Swift/Xcode versions
- [ ] Dependency versions
- [ ] iOS deployment target

### 5. **Quick Terminal Commands**

```bash
# Create a comparison script
cat > compare_projects.sh << 'EOF'
#!/bin/bash
WORKING="/的优势path/to/working-project"
NOT_WORKING="/path/to/not-working-project"

echo "=== Comparing Swift Files ==="
diff -rq "$WORKING" "$NOT_WORKING" --include="*.swift" | head -20

echo -e "\n=== Comparing Info.plist ==="
if [ -f "$WORKING/Info.plist" ] && [ -f "$NOT_WORKING/Info.plist" ]; then
    diff <(plutil -convert xml1 -o - "$WORKING/Info.plist") \
         <(plutil -convert xml1 -o - "$NOT_WORKING/Info.plist")
fi

echo -e "\n=== Comparing Entitlements ==="
diff -rq "$WORKING" "$NOT_WORKING" --include="*.entitlements"
EOF

chmod +x compare_projects.sh
```

### 6. **What to Look For Based on Your Recent Changes**

Looking at your modified `AppDelegate.swift` and `GlobulonApp.swift`:

**AppDelegate.swift:**
- [ ] Firebase setup sequence
- [ ] Delegate assignments
- [ ] Background task registration
- [ ] Notification setup

**GlobulonApp.swift:**
- [ ] `@UIApplicationDelegateAdaptor` assignment
- [ ] Model container initialization
- [ ] Environment object setup
- [ ] Startup sequence timing

### 7. **Xcode-Specific Checks**

1. **Project Navigator:**
   - Are all files included in target?
   - Check file membership (Target Membership)

2. **Build Phases:**
   - Compare "Compile Sources"
   - Compare "Link Binary With Libraries"
   - Compare "Copy Bundle Resources"

3. **Build Settings:**
   - Search for differences using Xcode's comparison view
   - Focus on: Swift flags, preprocessor macros, other Swift flags

4. **Signing & Capabilities:**
   - Compare all capabilities tabs
   - Background modes enabled?
   - Push notifications configured?

### 8. **Automated Approach**

```bash
# Find and compare all configuration-like files
find /path/to/working-project -name "*.plist" -o -name "*.entitlements" -o -name "project.pbxproj" | \
while read file; do
    other_file=$(echo "$file" | sed "s|working-project|not-working-project|")
    if [ -f "$other_file" ]; then
        echo "Comparing: $file"
        diff "$file" "$other_file" || echo "DIFFERENCE FOUND!"
    fi
done
```

## Pro Tips

1. **Start Small:** Compare one file at a time, starting with entry points
2. **Use Git:** If the working project is in git, use `git diff` to see recent changes
3. **Check Console Logs:** Run both apps and compare console output
4. **Build Logs:** Compare build logs for warnings/errors that differ
5. **Use Breakpoints:** Step through initialization in both to find where they diverge

