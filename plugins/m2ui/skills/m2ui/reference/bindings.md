# C++ Python Module Bindings

Exhaustive catalog of all C++ Python module functions available to Metin2 client UI code.
Extracted from `Python*Module.cpp` files in `client/Srcs/Client/`.

---

## wndMgr

Window manager — handles all UI window operations at C++ level. Most important module for UI work.

### Registration & Lifecycle

| Function | Purpose |
|----------|---------|
| `Register(pyObj, layer)` | Register Python window object in a UI layer |
| `RegisterSlotWindow(pyObj, layer)` | Register slot window |
| `RegisterGridSlotWindow(pyObj, layer)` | Register grid slot window |
| `RegisterTextLine(pyObj, layer)` | Register text line |
| `RegisterMarkBox(pyObj, layer)` | Register mark box |
| `RegisterImageBox(pyObj, layer)` | Register image box |
| `RegisterExpandedImageBox(pyObj, layer)` | Register expanded image box |
| `RegisterAniImageBox(pyObj, layer)` | Register animated image box |
| `RegisterButton(pyObj, layer)` | Register button |
| `RegisterRadioButton(pyObj, layer)` | Register radio button |
| `RegisterToggleButton(pyObj, layer)` | Register toggle button |
| `RegisterDragButton(pyObj, layer)` | Register drag button |
| `RegisterBox(pyObj, layer)` | Register box |
| `RegisterBar(pyObj, layer)` | Register bar |
| `RegisterLine(pyObj, layer)` | Register line |
| `RegisterBar3D(pyObj, layer)` | Register 3D bar |
| `RegisterNumberLine(pyObj, layer)` | Register number line |
| `RegisterCircle(pyObj, layer)` | Register circle widget |
| `RegisterMoveTextLine(pyObj, layer)` | Register moving text line |
| `RegisterMoveImageBox(pyObj, layer)` | Register moving image box |
| `RegisterMoveScaleImageBox(pyObj, layer)` | Register moving scale image box |
| `Destroy(handle)` | Destroy C++ window object |

### Window Properties

| Function | Purpose |
|----------|---------|
| `AddFlag(handle, flag)` | Add style flag to window |
| `IsRTL()` | Check if right-to-left layout |
| `SetName(handle, name)` | Set window name |
| `GetName(handle)` | Get window name |
| `SetTop(handle)` | Bring window to front (requires "float" flag) |
| `Show(handle)` | Show window |
| `Hide(handle)` | Hide window |
| `IsShow(handle)` | Check if visible |
| `SetParent(handle, parentHandle)` | Set parent window |
| `SetPickAlways(handle)` | Always pickable |
| `IsFocus(handle)` | Check if focused |
| `SetFocus(handle)` | Set focus |
| `KillFocus(handle)` | Remove focus |
| `Lock(handle)` | Lock window |
| `Unlock(handle)` | Unlock window |

### Size & Position

| Function | Purpose |
|----------|---------|
| `SetWindowSize(handle, w, h)` | Set window dimensions |
| `SetWindowPosition(handle, x, y)` | Set window position |
| `GetWindowWidth(handle)` | Get width |
| `GetWindowHeight(handle)` | Get height |
| `GetWindowLocalPosition(handle)` | Get position relative to parent |
| `GetWindowGlobalPosition(handle)` | Get absolute screen position |
| `GetWindowRect(handle)` | Get bounding rectangle |
| `SetWindowHorizontalAlign(handle, align)` | Set horizontal alignment |
| `SetWindowVerticalAlign(handle, align)` | Set vertical alignment |
| `UpdateRect(handle)` | Recalculate window rectangle |
| `SetLimitBias(handle, l, r, t, b)` | Set movement limit bias |
| `SetRestrictMovementArea(handle, x, y, w, h)` | Restrict drag area |
| `GetScreenWidth()` | Screen width |
| `GetScreenHeight()` | Screen height |
| `GetAspect()` | Screen aspect ratio |

### Picking & Mouse

| Function | Purpose |
|----------|---------|
| `SetMouseHandler(handler)` | Set mouse event handler |
| `GetChildCount(handle)` | Get number of children |
| `IsPickedWindow(handle)` | Check if mouse is over window |
| `IsIn(handle)` | Check if mouse is inside window |
| `GetMouseLocalPosition(handle)` | Mouse pos relative to window |
| `GetMousePosition()` | Absolute mouse position |
| `IsDragging()` | Check if dragging |
| `SetScreenSize(w, h)` | Set screen dimensions |
| `AttachIcon(type, index, slot, w, h)` | Attach icon to cursor |
| `DeattachIcon()` | Remove cursor icon |
| `SetAttachingFlag(flag)` | Set icon attach mode |
| `GetHyperlink()` | Get clicked hyperlink text |
| `OnceIgnoreMouseLeftButtonUpEvent()` | Skip next mouse up event |
| `SetWheelTopWindow(handle)` | Set wheel event target |
| `ClearWheelTopWindow()` | Clear wheel target |

### Slot Operations

| Function | Purpose |
|----------|---------|
| `AppendSlot(handle, index, x, y, w, h)` | Add slot at position |
| `ArrangeSlot(handle, startIndex, cols, rows, w, h, padX, padY)` | Create slot grid |
| `ClearSlot(handle, index)` | Clear single slot |
| `ClearAllSlot(handle)` | Clear all slots |
| `HasSlot(handle, index)` | Check if slot exists |
| `SetSlot(handle, index, itemIndex, w, h, icon)` | Set slot content |
| `SetSlotCount(handle, index, count)` | Set item count overlay |
| `SetSlotCountNew(handle, index, grade, count)` | Set count with grade |
| `SetSlotCoolTime(handle, index, coolTime, elapsedTime)` | Set cooldown overlay |
| `SetToggleSlot(handle, index)` | Toggle slot highlight |
| `ActivateSlot(handle, index)` | Activate slot (green border) |
| `DeactivateSlot(handle, index)` | Deactivate slot |
| `EnableSlot(handle, index)` | Enable slot interaction |
| `DisableSlot(handle, index)` | Disable slot (grayed out) |
| `ShowSlotBaseImage(handle, index)` | Show slot background |
| `HideSlotBaseImage(handle, index)` | Hide slot background |
| `SetSlotType(handle, type)` | Set slot type |
| `SetSlotStyle(handle, style)` | Set slot visual style |
| `SetSlotBaseImage(handle, image, r, g, b, a)` | Set base image with color |
| `SetCoverButton(handle, index, up, over, down, disable, flag)` | Add button overlay |
| `EnableCoverButton(handle, index)` | Enable cover button |
| `DisableCoverButton(handle, index)` | Disable cover button |
| `IsDisableCoverButton(handle, index)` | Check if disabled |
| `SetAlwaysRenderCoverButton(handle, index, flag)` | Always render overlay |
| `AppendSlotButton(handle, image, index)` | Add slot button |
| `AppendRequirementSignImage(handle, image, index)` | Add requirement sign |
| `ShowSlotButton(handle, index)` | Show slot button |
| `HideAllSlotButton(handle)` | Hide all slot buttons |
| `ShowRequirementSign(handle, index)` | Show requirement indicator |
| `HideRequirementSign(handle, index)` | Hide requirement indicator |
| `RefreshSlot(handle)` | Refresh all slots |
| `SetUseMode(handle, flag)` | Set use mode |
| `SetUsableItem(handle, flag)` | Set usable item flag |
| `SelectSlot(handle, index)` | Select a slot |
| `ClearSelected(handle)` | Clear selection |
| `GetSelectedSlotCount(handle)` | Count selected slots |
| `GetSelectedSlotNumber(handle, index)` | Get selected slot number |
| `IsSelectedSlot(handle, index)` | Check if slot selected |
| `GetSlotCount(handle)` | Get total slot count |
| `LockSlot(handle, index)` | Lock slot |
| `UnlockSlot(handle, index)` | Unlock slot |
| `IsActivatedSlot(handle, index)` | Check if activated |
| `GetSlotCoolTime(handle, index)` | Get remaining cooldown |
| `SetSlotDiffuseColor(handle, index, r, g, b, a)` | Set slot tint color |
| `SetColor(handle, color)` | Set element color |

### Text Operations

| Function | Purpose |
|----------|---------|
| `SetMax(handle, max)` | Set max input length |
| `SetHorizontalAlign(handle, align)` | Set text h-align |
| `SetVerticalAlign(handle, align)` | Set text v-align |
| `SetSecret(handle, flag)` | Set password mode |
| `SetOutline(handle, flag)` | Set text outline |
| `SetFeather(handle, flag)` | Set text feather effect |
| `SetMultiLine(handle, flag)` | Enable multiline |
| `SetText(handle, text)` | Set text content |
| `SetFontName(handle, font)` | Set font |
| `SetFontColor(handle, r, g, b)` | Set text color |
| `SetLimitWidth(handle, width)` | Set text width limit |
| `GetText(handle)` | Get text content |
| `GetTextSize(handle)` | Get text pixel dimensions |
| `ShowCursor(handle)` | Show edit cursor |
| `HideCursor(handle)` | Hide edit cursor |
| `GetCursorPosition(handle)` | Get cursor position |

### Number Line

| Function | Purpose |
|----------|---------|
| `SetNumber(handle, number)` | Set displayed number |
| `SetNumberHorizontalAlignCenter(handle)` | Center number |
| `SetNumberHorizontalAlignRight(handle)` | Right-align number |
| `SetPath(handle, path)` | Set number image path |

### Image Operations

| Function | Purpose |
|----------|---------|
| `MarkBox_SetImage(handle, image)` | Set mark image |
| `MarkBox_SetImageFilename(handle, filename)` | Set mark filename |
| `MarkBox_Load(handle)` | Load mark |
| `MarkBox_SetIndex(handle, index)` | Set mark index |
| `MarkBox_SetScale(handle, scale)` | Set mark scale |
| `MarkBox_SetDiffuseColor(handle, r, g, b, a)` | Set mark color |
| `LoadImage(handle, filename)` | Load image file |
| `SetDiffuseColor(handle, r, g, b, a)` | Set image tint |
| `GetWidth(handle)` | Get image width |
| `GetHeight(handle)` | Get image height |
| `SetScale(handle, xScale, yScale)` | Set image scale |
| `SetOrigin(handle, x, y)` | Set rotation origin |
| `SetRotation(handle, degrees)` | Set rotation angle |
| `SetRenderingRect(handle, l, t, r, b)` | Set rendering rect (for fill effects) |
| `SetRenderingMode(handle, mode)` | Set blend mode |
| `LeftRightReverseImageBox(handle)` | Mirror image horizontally |
| `LeftRightReverse(handle)` | Mirror (alias) |

### Animation

| Function | Purpose |
|----------|---------|
| `SetDelay(handle, delay)` | Set animation frame delay |
| `AppendImage(handle, filename)` | Add animation frame |

### Button Operations

| Function | Purpose |
|----------|---------|
| `SetUpVisual(handle, filename)` | Set button normal image |
| `SetOverVisual(handle, filename)` | Set button hover image |
| `SetDownVisual(handle, filename)` | Set button pressed image |
| `SetDisableVisual(handle, filename)` | Set button disabled image |
| `GetUpVisualFileName(handle)` | Get normal image path |
| `GetOverVisualFileName(handle)` | Get hover image path |
| `GetDownVisualFileName(handle)` | Get pressed image path |
| `Flash(handle)` | Flash button |
| `Enable(handle)` | Enable button |
| `Disable(handle)` | Disable button |
| `Down(handle)` | Force pressed state |
| `SetUp(handle)` | Force released state |
| `IsDown(handle)` | Check if pressed |
| `SetOutlineFlag(handle, flag)` | Set button outline |
| `ShowOverInWindowName(handle, name)` | Show name on hover |

### Move & Scale

| Function | Purpose |
|----------|---------|
| `SetMoveSpeed(handle, speed)` | Set move animation speed |
| `SetMovePosition(handle, x, y)` | Set move target position |
| `MoveStart(handle)` | Start move animation |
| `MoveStop(handle)` | Stop move animation |
| `GetMove(handle)` | Get move state |
| `SetMaxScale(handle, scale)` | Set max scale for animation |
| `SetMaxScaleRate(handle, rate)` | Set scale rate |
| `SetScalePivotCenter(handle)` | Set scale pivot to center |

### Clipping

| Function | Purpose |
|----------|---------|
| `SetClippingMaskRect(handle, l, t, r, b)` | Set clipping mask rectangle |
| `SetClippingMaskWindow(handle, maskHandle)` | Set clipping mask window |

---

## app

Application state, feature flags, time, input, camera.

### Core

| Function | Purpose |
|----------|---------|
| `GetTime()` | Current game time (float seconds) |
| `GetGlobalTime()` | Global time |
| `GetGlobalTimeStamp()` | Unix timestamp |
| `GetRandom(min, max)` | Random integer in range |
| `IsPressed(key)` | Check if key is currently pressed |
| `GetCursorPosition()` | Get cursor screen position |
| `Sleep(ms)` | Sleep milliseconds |
| `Exit()` | Exit application |
| `Abort()` | Abort with error |

### Camera

| Function | Purpose |
|----------|---------|
| `SetCamera(distance, pitch, rotation, height)` | Set camera |
| `GetCamera()` | Get camera params |
| `GetCameraPitch()` | Get pitch |
| `GetCameraRotation()` | Get rotation |
| `RotateCamera(direction)` | Rotate camera |
| `PitchCamera(direction)` | Pitch camera |
| `ZoomCamera(direction)` | Zoom camera |
| `SetCameraMaxDistance(dist)` | Set max zoom out |
| `SetSightRange(range)` | Set view distance |
| `EnableSpecialCameraMode()` | Enable special camera |
| `SetCameraSpeed(speed)` | Set camera speed |
| `SetDefaultCamera()` | Reset to default |

### Display

| Function | Purpose |
|----------|---------|
| `GetUpdateFPS()` | Current update FPS |
| `GetRenderFPS()` | Current render FPS |
| `SetFPS(fps)` | Set target FPS |
| `SetCursor(type)` | Set cursor shape |
| `GetCursor()` | Get current cursor |
| `ShowCursor()` | Show cursor |
| `HideCursor()` | Hide cursor |
| `IsShowCursor()` | Check cursor visible |

### File & Locale

| Function | Purpose |
|----------|---------|
| `IsExistFile(path)` | Check file exists |
| `GetLocaleServiceName()` | Get locale service name |
| `GetLocaleName()` | Get locale name |
| `GetLocalePath()` | Get locale path |
| `RunPythonFile(path)` | Execute Python file |

### Build Flags

| Function | Purpose |
|----------|---------|
| `IsDevStage()` | Check if dev build |
| `IsTestStage()` | Check if test build |
| `IsLiveStage()` | Check if live build |

### Feature Flags (app.ENABLE_* / app.BL_*)

Used for conditional UI code: `if app.ENABLE_COSTUME_SYSTEM:`.

| Flag | Description |
|------|-------------|
| `ENABLE_COSTUME_SYSTEM` | Costume equipment slots |
| `ENABLE_MOUNT_COSTUME_SYSTEM` | Mount costume slot |
| `ENABLE_WEAPON_COSTUME_SYSTEM` | Weapon costume slot |
| `ENABLE_ACCE_SYSTEM` | Acce (sash) system |
| `ENABLE_ACCE_COSTUME_SYSTEM` | Acce costume variant |
| `ENABLE_USE_COSTUME_ATTR` | Costume attributes |
| `ENABLE_ENERGY_SYSTEM` | Energy system |
| `ENABLE_DRAGON_SOUL_SYSTEM` | Dragon soul alchemy |
| `ENABLE_DS_GRADE_MYTH` | Mythic dragon soul grade |
| `ENABLE_NEW_EQUIPMENT_SYSTEM` | Belt/pendant equipment |
| `ENABLE_PENDANT_SYSTEM` | Pendant slot |
| `ENABLE_GLOVE_SYSTEM` | Glove slot |
| `ENABLE_SOULBIND_SYSTEM` | Item soul binding |
| `ENABLE_PLAYER_PER_ACCOUNT5` | 5 characters per account |
| `ENABLE_WOLFMAN_CHARACTER` | Wolfman race |
| `ENABLE_QUIVER_SYSTEM` | Arrow quiver |
| `ENABLE_LEVEL_IN_TRADE` | Show level in trade |
| `ENABLE_678TH_SKILL` | 6th/7th/8th skill pages |
| `ENABLE_CHEQUE_SYSTEM` | Won currency |
| `ENABLE_EXTEND_INVEN_SYSTEM` | Extended inventory |
| `ENABLE_SLOT_WINDOW_EX` | Extended slot window |
| `ENABLE_HIGHLIGHT_NEW_ITEM` | Highlight new items |
| `ENABLE_GROWTH_PET_SYSTEM` | Growth pet UI |
| `ENABLE_AUTO_SYSTEM` | Auto-hunt system |
| `ENABLE_MONSTER_CARD` | Monster card system |
| `ENABLE_HELP_RENEWAL` | Renewed help UI |
| `ENABLE_MAGIC_REDUCTION_SYSTEM` | Magic reduction stat |
| `ENABLE_DICE_SYSTEM` | Party dice rolling |
| `ENABLE_ENVIRONMENT_EFFECT_OPTION` | Weather settings |
| `ENABLE_NO_SELL_PRICE_DIVIDED_BY_5` | Full sell price |
| `ENABLE_GOLD_FIELD_AS_SELL_PRICE` | Gold field sell price |
| `ENABLE_MOVE_CHANNEL` | Channel switching UI |
| `ENABLE_RACE_HEIGHT` | Race-based height |
| `ENABLE_ELEMENTAL_TARGET` | Elemental target info |
| `ENABLE_UI_CIRCLE` | Circle widget type |
| `ENABLE_UI_MOVING` | Animated moving widgets |
| `ENABLE_AUTO_L2R` | Auto left-to-right layout |
| `ENABLE_CONQUEROR_LEVEL` | Conqueror level system |
| `ENABLE_CONQUEROR_UI` | Conqueror UI elements |
| `ENABLE_WON_EXCHANGE_WINDOW` | Won exchange window |
| `ENABLE_MINIMAP_TELEPORT_CLICK` | Minimap teleport |
| `ENABLE_ATLAS_MARK_ON_WARP_SCROLLS` | Atlas warp marks |
| `ENABLE_PREMIUM_LOOT_FILTER` | Premium loot filter |
| `ENABLE_PET_SYSTEM_EX` | Extended pet system |
| `ENABLE_LOCALE_COMMON` | Common locale support |
| `ENABLE_EMOJI_SYSTEM` | Emoji system |
| `ENABLE_MOUSEWHEEL_EVENT` | Mouse wheel events |
| `ENABLE_NO_DSS_QUALIFICATION` | Skip DSS qualification |
| `ENABLE_LVL115_ARMOR_EFFECT` | Level 115 armor effect |
| `BL_ENABLE_PICKUP_ITEM_EFFECT` | Pickup item effect |
| `__BL_OFFICIAL_LOOT_FILTER__` | Official loot filter |
| `__BL_FOG_FIX__` | Fog rendering fix |
| `__BL_MOUSE_WHEEL_TOP_WINDOW__` | Wheel targets top window |
| `__BL_CLIP_MASK__` | Clipping mask support |
| `DISABLE_CHEQUE_DROP` | Disable cheque dropping |

### Cursor Shape Constants

| Constant | Purpose |
|----------|---------|
| `NORMAL` | Default cursor |
| `ATTACK` | Attack cursor |
| `TARGET` | Target cursor |
| `TALK` | NPC talk cursor |
| `CANT_GO` | Blocked movement |
| `PICK` | Item pickup cursor |
| `DOOR` | Door interact cursor |
| `CHAIR` | Chair sit cursor |
| `MAGIC` | Magic cast cursor |
| `BUY` | Shop buy cursor |
| `SELL` | Shop sell cursor |

---

## player

Player data access — inventory, stats, skills, party.

### Identity

| Function | Purpose |
|----------|---------|
| `GetName()` | Player character name |
| `GetJob()` | Character class (0-4) |
| `GetRace()` | Character race |
| `GetPlayTime()` | Total play time |
| `GetMainCharacterIndex()` | Main character VID |
| `GetMainCharacterName()` | Main character name |
| `GetMainCharacterPosition()` | World position |
| `IsMainCharacterIndex(vid)` | Check if VID is main char |

### Stats & Resources

| Function | Purpose |
|----------|---------|
| `GetStatus(type)` | Get stat value (HP, SP, STR, DEX, etc.) |
| `SetStatus(type, value)` | Set stat value |
| `GetEXP()` | Current experience |
| `GetElk()` | Gold amount |
| `GetMoney()` | Gold (alias) |
| `GetCheque()` | Won currency amount |
| `GetGuildID()` | Player guild ID |
| `GetGuildName()` | Player guild name |
| `GetAlignmentData()` | Alignment/karma data |
| `GetPKMode()` | PK mode state |

### Inventory

| Function | Purpose |
|----------|---------|
| `GetItemIndex(window, slot)` | Get item VNUM at slot |
| `GetItemFlags(window, slot)` | Get item flags |
| `GetItemCount(window, slot)` | Get stack count |
| `GetItemCountByVnum(vnum)` | Count items by VNUM |
| `GetItemMetinSocket(window, slot, socketIdx)` | Get metin socket value |
| `GetItemAttribute(window, slot, attrIdx)` | Get item attribute |
| `GetISellItemPrice(window, slot)` | Get sell price |
| `GetItemGrade(window, slot)` | Get item grade |
| `GetItemLink(window, slot)` | Get item chat link string |
| `GetItemSealDate(window, slot)` | Get seal date |
| `GetItemUnSealLeftTime(window, slot)` | Time until unseal |
| `MoveItem(srcWin, srcSlot, dstWin, dstSlot)` | Move item |
| `SetItemData(window, slot, vnum, count)` | Set item data |
| `SetItemMetinSocket(window, slot, idx, value)` | Set socket |
| `SetItemAttribute(window, slot, idx, type, value)` | Set attribute |
| `SetItemCount(window, slot, count)` | Set count |
| `RefreshInventory()` | Refresh inventory display |
| `SendClickItemPacket(window, slot)` | Click item |
| `CanRefine()` | Check if refinable |
| `CanDetach()` | Check if detachable |
| `CanUnlock()` | Check if unlockable |
| `CanAttachMetin()` | Check metin attachable |
| `CanSealItem()` | Check if sealable |
| `IsRefineGradeScroll()` | Check if refine scroll |
| `isItem(window, slot)` | Check if slot has item |
| `IsEquipmentSlot(slot)` | Check if equipment slot |
| `IsDSEquipmentSlot(slot)` | Check if dragon soul slot |
| `IsCostumeSlot(slot)` | Check if costume slot |
| `IsBeltInventorySlot(slot)` | Check if belt slot |
| `IsEquippingBelt()` | Check belt equipped |
| `IsAvailableBeltInventoryCell(slot)` | Check belt cell usable |
| `IsValuableItem(window, slot)` | Check if valuable |
| `SlotTypeToInvenType(slotType)` | Convert slot type |

### Skills

| Function | Purpose |
|----------|---------|
| `SetSkill(slotIndex, skillIndex)` | Set skill in slot |
| `GetSkillIndex(slot)` | Get skill index |
| `GetSkillSlotIndex(skillIdx)` | Get slot for skill |
| `GetSkillGrade(slot)` | Get skill grade |
| `GetSkillLevel(slot)` | Get skill level |
| `GetSkillCurrentEfficientPercentage(slot)` | Current efficiency % |
| `GetSkillNextEfficientPercentage(slot)` | Next level efficiency % |
| `ClickSkillSlot(slot)` | Use skill |
| `IsSkillCoolTime(slot)` | Check cooldown active |
| `GetSkillCoolTime(slot)` | Get remaining cooldown |
| `IsSkillActive(slot)` | Check if skill active |
| `UseGuildSkill(skillIdx)` | Use guild skill |
| `AffectIndexToSkillIndex(affectIdx)` | Convert affect to skill |

### Quick Slots

| Function | Purpose |
|----------|---------|
| `GetQuickPage()` | Get current quick slot page |
| `SetQuickPage(page)` | Set quick slot page |
| `GetLocalQuickSlot(slot)` | Get local quick slot |
| `GetGlobalQuickSlot(slot)` | Get global quick slot |
| `RequestAddLocalQuickSlot(slot, type, value)` | Add to quick slot |
| `RequestAddToEmptyLocalQuickSlot(type, value)` | Add to empty slot |
| `RequestDeleteGlobalQuickSlot(slot)` | Delete quick slot |
| `RequestUseLocalQuickSlot(slot)` | Use quick slot |
| `RemoveQuickSlotByValue(type, value)` | Remove by value |

### Party

| Function | Purpose |
|----------|---------|
| `IsPartyMember(vid)` | Check if party member |
| `IsPartyLeader(vid)` | Check if party leader |
| `IsPartyLeaderByPID(pid)` | Check leader by PID |
| `GetPartyMemberHPPercentage(pid)` | Get member HP % |
| `GetPartyMemberState(pid)` | Get member state |
| `GetPartyMemberAffects(pid)` | Get member affects |
| `RemovePartyMember(pid)` | Remove from party |
| `ExitParty()` | Leave party |

### Combat & Target

| Function | Purpose |
|----------|---------|
| `SetTarget(vid)` | Set target |
| `ClearTarget()` | Clear target |
| `GetTargetVID()` | Get target VID |
| `CanAttackInstance(vid)` | Check if attackable |
| `IsPVPInstance(vid)` | Check if PVP target |
| `IsChallengeInstance(vid)` | Check challenge |
| `IsRevengeInstance(vid)` | Check revenge |
| `IsCantFightInstance(vid)` | Check can't fight |
| `GetCharacterDistance(vid)` | Distance to character |
| `IsInSafeArea()` | Check safe zone |
| `IsMountingHorse()` | Check mounted |
| `IsObserverMode()` | Check observer |
| `CheckAffect(affectType)` | Check active affect |

### Misc

| Function | Purpose |
|----------|---------|
| `SetGameWindow(window)` | Set game window ref |
| `OpenCharacterMenu(vid)` | Open char context menu |
| `IsOpenPrivateShop()` | Check private shop open |
| `ToggleCoolTime()` | Toggle cooldown display |
| `ToggleLevelLimit()` | Toggle level limit |
| `GetAutoPotionInfo(type)` | Get auto potion config |
| `SetAutoPotionInfo(type, config)` | Set auto potion config |
| `SendDragonSoulRefine(type, args)` | Dragon soul refine |
| `RegisterEmotionIcon(idx, image)` | Register emotion icon |
| `GetEmotionIconImage(idx)` | Get emotion icon |

---

## item

Item data from item_proto.

| Function | Purpose |
|----------|---------|
| `SelectItem(vnum)` | Select item for queries |
| `GetItemName()` | Get selected item name |
| `GetItemDescription()` | Get description |
| `GetItemSummary()` | Get summary text |
| `GetIconImage()` | Get icon image object |
| `GetIconImageFileName()` | Get icon path |
| `GetItemSize()` | Get item grid size (w, h) |
| `GetItemType()` | Get item type |
| `GetItemSubType()` | Get item subtype |
| `GetIBuyItemPrice()` | Get buy price |
| `GetISellItemPrice()` | Get sell price |
| `IsAntiFlag(flag)` | Check anti flag |
| `IsFlag(flag)` | Check item flag |
| `IsWearableFlag(flag)` | Check wearable flag |
| `Is1GoldItem()` | Check if 1 gold item |
| `GetLimit(idx)` | Get limit (type, value) |
| `GetAffect(idx)` | Get affect (type, value) |
| `GetValue(idx)` | Get value field |
| `GetSocket(idx)` | Get socket info |
| `GetIconInstance()` | Get icon instance |
| `GetUseType(vnum)` | Get use type |
| `DeleteIconInstance()` | Delete icon |
| `IsEquipmentVID(vnum)` | Check if equipment |
| `IsRefineScroll(vnum)` | Check refine scroll |
| `IsDetachScroll(vnum)` | Check detach scroll |
| `IsKey(vnum)` | Check if key item |
| `IsMetin(vnum)` | Check if metin stone |
| `CanAddToQuickSlotItem(vnum)` | Check quick-slottable |
| `LoadItemTable(filename)` | Load item proto |
| `GetApplyPoint(applyType)` | Get apply point name |
| `IsSealScroll(vnum)` | Check seal scroll |
| `GetDefaultSealDate()` | Default seal duration |
| `GetUnlimitedSealDate()` | Unlimited seal constant |
| `SaveLootingSettings()` | Save loot filter |

---

## net

Network stream — send packets to server, get connection info.

### Connection

| Function | Purpose |
|----------|---------|
| `SetServerInfo(addr, port)` | Set server address |
| `GetServerInfo()` | Get server address |
| `ConnectTCP(addr, port)` | Connect TCP |
| `ConnectToAccountServer()` | Connect to login server |
| `Disconnect()` | Disconnect |
| `IsConnect()` | Check connected |
| `SetOfflinePhase()` | Enter offline phase |
| `DirectEnter()` | Direct enter game |

### Login & Character

| Function | Purpose |
|----------|---------|
| `SetLoginInfo(id, pwd)` | Set login credentials |
| `SendLoginPacket()` | Send login |
| `SendSelectEmpirePacket(empire)` | Select empire |
| `SendSelectCharacterPacket(slot)` | Select character |
| `SendCreateCharacterPacket(slot, name, race, shape)` | Create character |
| `SendDestroyCharacterPacket(slot)` | Delete character |
| `SendChangeNamePacket(slot, name)` | Change name |
| `SendEnterGamePacket()` | Enter game world |
| `GetAccountCharacterSlotDataInteger(slot, type)` | Char slot int data |
| `GetAccountCharacterSlotDataString(slot, type)` | Char slot string data |

### Game Session

| Function | Purpose |
|----------|---------|
| `StartGame()` | Start game session |
| `Warp(x, y)` | Warp to coordinates |
| `LogOutGame()` | Logout |
| `ExitGame()` | Exit game |
| `ExitApplication()` | Exit app |

### Item Packets

| Function | Purpose |
|----------|---------|
| `SendItemUsePacket(window, slot)` | Use item |
| `SendItemUseToItemPacket(srcWin, srcSlot, dstWin, dstSlot)` | Use item on item |
| `SendItemDropPacket(window, slot)` | Drop item |
| `SendItemDropPacketNew(window, slot, count)` | Drop with count |
| `SendElkDropPacket(amount)` | Drop gold |
| `SendGoldDropPacketNew(amount)` | Drop gold (new) |
| `SendItemMovePacket(srcWin, srcSlot, dstWin, dstSlot, count)` | Move item |
| `SendItemPickUpPacket(vid)` | Pick up item |
| `SendGiveItemPacket(vid, window, slot, count)` | Give item |
| `SendSelectItemPacket(window, slot)` | Select item |

### Chat & Whisper

| Function | Purpose |
|----------|---------|
| `SendChatPacket(text, type)` | Send chat message |
| `SendEmoticon(emoticon)` | Send emoticon |
| `SendWhisperPacket(name, text)` | Send whisper |

### Shop

| Function | Purpose |
|----------|---------|
| `SendShopEndPacket()` | Close shop |
| `SendShopBuyPacket(slot)` | Buy from shop |
| `SendShopSellPacket(window, slot)` | Sell to shop |
| `SendShopSellPacketNew(window, slot, count)` | Sell with count |

### Exchange

| Function | Purpose |
|----------|---------|
| `SendExchangeStartPacket(vid)` | Start trade |
| `SendExchangeItemAddPacket(window, slot, displaySlot)` | Add item |
| `SendExchangeItemDelPacket(displaySlot)` | Remove item |
| `SendExchangeElkAddPacket(amount)` | Add gold |
| `SendExchangeAcceptPacket()` | Accept trade |
| `SendExchangeExitPacket()` | Cancel trade |
| `SendExchangeChequeAddPacket(amount)` | Add won |

### Party

| Function | Purpose |
|----------|---------|
| `SendPartyInvitePacket(vid)` | Invite to party |
| `SendPartyInviteAnswerPacket(vid, answer)` | Answer invite |
| `SendPartyExitPacket()` | Leave party |
| `SendPartyRemovePacket(pid)` | Kick member |
| `SendPartySetStatePacket(pid, state)` | Set member state |
| `SendPartyUseSkillPacket(skillIdx, vid)` | Use party skill |
| `SendPartyParameterPacket(distribute)` | Set party params |

### Guild

| Function | Purpose |
|----------|---------|
| `SendAnswerMakeGuildPacket(name)` | Create guild |
| `SendGuildAddMemberPacket(vid)` | Add guild member |
| `SendGuildRemoveMemberPacket(pid)` | Remove member |
| `SendGuildChangeGradeNamePacket(grade, name)` | Rename grade |
| `SendGuildChangeGradeAuthorityPacket(grade, auth)` | Set grade perms |
| `SendGuildOfferPacket(amount)` | Offer EXP |
| `SendGuildPostCommentPacket(text)` | Post comment |
| `SendGuildDeleteCommentPacket(idx)` | Delete comment |
| `SendGuildRefreshCommentsPacket()` | Refresh comments |
| `SendGuildChangeMemberGradePacket(pid, grade)` | Change member grade |
| `SendGuildUseSkillPacket(skillIdx)` | Use guild skill |
| `SendGuildChangeMemberGeneralPacket(pid, flag)` | Set general flag |
| `SendGuildInviteAnswerPacket(guildId, answer)` | Answer invite |
| `SendGuildChargeGSPPacket(amount)` | Charge GSP |
| `SendGuildDepositMoneyPacket(amount)` | Deposit gold |
| `SendGuildWithdrawMoneyPacket(amount)` | Withdraw gold |

### Safebox / Mall

| Function | Purpose |
|----------|---------|
| `SendSafeboxSaveMoneyPacket(amount)` | Deposit to safebox |
| `SendSafeboxWithdrawMoneyPacket(amount)` | Withdraw from safebox |
| `SendSafeboxCheckinPacket(window, slot, safeSlot)` | Put in safebox |
| `SendSafeboxCheckoutPacket(safeSlot, window, slot)` | Take from safebox |
| `SendSafeboxItemMovePacket(srcSlot, dstSlot)` | Move in safebox |
| `SendMallCheckoutPacket(mallSlot, window, slot)` | Take from mall |

### Quest

| Function | Purpose |
|----------|---------|
| `SendQuestInputStringPacket(text)` | Send quest input |
| `SendQuestConfirmPacket(answer, pid)` | Confirm quest |

### Refine

| Function | Purpose |
|----------|---------|
| `SendRequestRefineInfoPacket(window, slot)` | Request refine info |
| `SendRefinePacket(window, slot, type)` | Refine item |

### Misc

| Function | Purpose |
|----------|---------|
| `GetGuildID()` | Get guild ID |
| `GetEmpireID()` | Get empire (kingdom) |
| `GetMainActorVID()` | Get main char VID |
| `GetMainActorRace()` | Get main char race |
| `GetMainActorEmpire()` | Get main char empire |
| `GetMainActorSkillGroup()` | Get skill group |
| `IsTest()` | Test server flag |
| `SendOnClickPacket(vid)` | NPC click |
| `SendMobileMessagePacket(name, text)` | Mobile message |
| `RegisterEmoticonString(idx, text)` | Register emoticon string |
| `PreserveServerCommand(cmd)` | Queue server command |
| `GetPreservedServerCommand()` | Get queued command |
| `EnableChatInsultFilter(flag)` | Toggle chat filter |
| `IsChatInsultIn(text)` | Check insult |
| `IsInsultIn(text)` | Check insult (alias) |
| `LoadInsultList(filename)` | Load insult list |
| `ToggleGameDebugInfo()` | Toggle debug info |
| `SetPacketSequenceMode()` | Set packet sequence |
| `SetEmpireLanguageMode(flag)` | Empire language filter |
| `GetLoginID()` | Get login account ID |
| `UploadMark(guildId, image)` | Upload guild mark |
| `UploadSymbol(filename)` | Upload guild symbol |
| `SetMarkServer(addr, port)` | Set mark server |
| `SetSkillGroupFake(group)` | Set skill group |
| `RegisterErrorLog(text)` | Register error log |
| `GetFieldMusicFileName()` | Get field music path |
| `GetFieldMusicVolume()` | Get field music volume |
| `SetPhaseWindow(phase, window)` | Set phase window |
| `ClearPhaseWindow(phase, window)` | Clear phase window |
| `SetServerCommandParserWindow(window)` | Set command parser |
| `SetAccountConnectorHandler(handler)` | Set connector handler |
| `SetHandler(handler)` | Set main handler |
| `SetTCPRecvBufferSize(size)` | Set recv buffer |
| `SetTCPSendBufferSize(size)` | Set send buffer |
| `GetBettingGuildWarValue(type)` | Get guild war bet |

---

## chr

Character instance control — appearance, animation, effects.

| Function | Purpose |
|----------|---------|
| `CreateInstance(vid)` | Create character instance |
| `DeleteInstance(vid)` | Delete character |
| `DeleteInstanceByFade(vid)` | Fade-delete character |
| `SelectInstance(vid)` | Select for manipulation |
| `HasInstance(vid)` | Check if exists |
| `IsEnemy(vid)` | Check if enemy |
| `IsNPC(vid)` | Check if NPC |
| `IsGameMaster(vid)` | Check if GM |
| `IsPartyMember(vid)` | Check if party member |
| `SetArmor(armorVnum)` | Set armor appearance |
| `SetWeapon(weaponVnum)` | Set weapon |
| `ChangeShape(shape)` | Change shape |
| `SetRace(race)` | Set character race |
| `SetHair(hair)` | Set hair style |
| `SetAcce(acce)` | Set acce/sash |
| `SetNameString(name)` | Set display name |
| `SetInstanceType(type)` | Set instance type |
| `SetPixelPosition(x, y, z)` | Set world position |
| `SetDirection(dir)` | Set facing direction |
| `SetRotation(rot)` | Set rotation |
| `GetRotation()` | Get rotation |
| `GetPixelPosition()` | Get world position (x, y, z) |
| `GetRace()` | Get race |
| `GetName()` | Get name |
| `GetNameByVID(vid)` | Get name by VID |
| `GetGuildID()` | Get guild ID |
| `GetProjectPosition()` | Get screen projection |
| `GetVirtualNumber()` | Get VNUM |
| `GetInstanceType()` | Get instance type |
| `Show()` | Show character |
| `Hide()` | Hide character |
| `Pick()` | Pick (raycast) |
| `LookAt(vid)` | Look at target |
| `SetMoveSpeed(speed)` | Set move speed |
| `SetAttackSpeed(speed)` | Set attack speed |
| `Refresh()` | Refresh appearance |
| `Revive()` | Revive |
| `Die()` | Kill |
| `AttachEffectByID(effectId)` | Attach effect by ID |
| `AttachEffectByName(boneName, effectPath)` | Attach effect by name |
| `Select()` | Select (highlight) |
| `Unselect()` | Deselect |
| `SetMotionMode(mode)` | Set motion mode |
| `SetLoopMotion(motion)` | Set loop motion |
| `MoveToDestPosition(x, y)` | Move character |

---

## chrMgr

Character manager — race data, effects, motion registration.

| Function | Purpose |
|----------|---------|
| `SetEmpireNameMode(mode)` | Name display mode |
| `GetVIDInfo(vid)` | Get VID info string |
| `GetPickedVID()` | Get mouse-picked VID |
| `SetShapeModel(race, shape, path)` | Set shape model |
| `AppendShapeSkin(race, shape, path)` | Add shape skin |
| `SetPathName(path)` | Set resource path |
| `LoadRaceData(filename)` | Load race data |
| `CreateRace(race)` | Create race |
| `SelectRace(race)` | Select race for config |
| `RegisterMotionMode(mode)` | Register motion mode |
| `RegisterMotion(mode, type, filename)` | Register motion |
| `RegisterNormalAttack(mode, type)` | Register normal attack |
| `RegisterComboAttack(args)` | Register combo |
| `RegisterEffect(effectId, path)` | Register effect |
| `RegisterCacheEffect(effectId, path)` | Cache effect |
| `RegisterPointEffect(effectId, path)` | Point effect |
| `ShowPointEffect(effectId, vid)` | Show point effect |
| `RegisterTitleName(idx, name)` | Register title name |
| `RegisterNameColor(type, r, g, b)` | Register name color |
| `RegisterTitleColor(idx, r, g, b)` | Register title color |
| `SetMovingSpeed(race, speed)` | Set moving speed |
| `HasAffectByVID(vid, affect)` | Check affect on VID |
| `GetMainVID()` | Get main character VID |
| `SetRaceHeight(race, height)` | Set race height |

---

## exchange

Trade window data access.

| Function | Purpose |
|----------|---------|
| `InitTrading()` | Reset trade state |
| `isTrading()` | Check if trading |
| `GetElkFromSelf()` | Gold offered by self |
| `GetElkFromTarget()` | Gold offered by target |
| `GetChequeFromSelf()` | Won offered by self |
| `GetChequeFromTarget()` | Won offered by target |
| `GetItemVnumFromSelf(slot)` | Self item VNUM |
| `GetItemVnumFromTarget(slot)` | Target item VNUM |
| `GetItemCountFromSelf(slot)` | Self item count |
| `GetItemCountFromTarget(slot)` | Target item count |
| `GetAcceptFromSelf()` | Self accept state |
| `GetAcceptFromTarget()` | Target accept state |
| `GetNameFromSelf()` | Self name |
| `GetNameFromTarget()` | Target name |
| `GetLevelFromSelf()` | Self level |
| `GetLevelFromTarget()` | Target level |
| `GetItemMetinSocketFromSelf(slot, idx)` | Self item socket |
| `GetItemMetinSocketFromTarget(slot, idx)` | Target item socket |
| `GetItemAttributeFromSelf(slot, idx)` | Self item attribute |
| `GetItemAttributeFromTarget(slot, idx)` | Target item attribute |
| `GetElkMode()` | Get gold input mode |
| `SetElkMode(mode)` | Set gold input mode |

---

## chat

Chat system.

| Function | Purpose |
|----------|---------|
| `SetChatColor(type, r, g, b)` | Set chat color by type |
| `Clear()` | Clear chat |
| `Close()` | Close chat |
| `CreateChatSet(setId)` | Create chat set |
| `SetBoardState(setId, state)` | Set chat board state |
| `SetPosition(setId, x, y)` | Set chat position |
| `SetHeight(setId, height)` | Set chat height |
| `SetStep(setId, step)` | Set line step |
| `ToggleChatMode(setId)` | Toggle input mode |
| `EnableChatMode(setId)` | Enable input |
| `DisableChatMode(setId)` | Disable input |
| `SetEndPos(setId, pos)` | Set scroll end |
| `GetLineCount(setId)` | Get line count |
| `GetVisibleLineCount(setId)` | Get visible lines |
| `GetLineStep(setId)` | Get line step |
| `AppendChat(setId, type, text)` | Add chat line |
| `AppendChatWithDelay(setId, type, text, delay)` | Add with delay |
| `ArrangeShowingChat(setId)` | Arrange display |
| `IgnoreCharacter(name)` | Block character |
| `IsIgnoreCharacter(name)` | Check if blocked |
| `CreateWhisper(name)` | Create whisper window |
| `AppendWhisper(type, name, text)` | Add whisper line |
| `RenderWhisper(name)` | Render whisper |
| `SetWhisperBoxSize(name, w, h)` | Set whisper size |
| `SetWhisperPosition(name, x, y)` | Set whisper position |
| `ClearWhisper(name)` | Clear whisper |
| `InitWhisper(name)` | Init whisper |
| `GetLinkFromHyperlink(hyperlink)` | Parse hyperlink |
| `Update(setId)` | Update chat |
| `Render(setId)` | Render chat |

---

## miniMap

Minimap and atlas.

| Function | Purpose |
|----------|---------|
| `Create()` | Create minimap |
| `Destroy()` | Destroy minimap |
| `Update(x, y)` | Update position |
| `Render()` | Render minimap |
| `Show()` | Show minimap |
| `Hide()` | Hide minimap |
| `isShow()` | Check visible |
| `SetScale(scale)` | Set zoom level |
| `ScaleUp()` | Zoom in |
| `ScaleDown()` | Zoom out |
| `SetMiniMapSize(w, h)` | Set display size |
| `SetCenterPosition(x, y)` | Set center |
| `GetInfo(x, y)` | Get info at position |
| `LoadAtlas()` | Load world atlas |
| `UpdateAtlas()` | Update atlas |
| `RenderAtlas()` | Render atlas |
| `ShowAtlas()` | Show atlas |
| `HideAtlas()` | Hide atlas |
| `isShowAtlas()` | Check atlas visible |
| `IsAtlas()` | Check atlas loaded |
| `GetAtlasInfo(x, y)` | Get atlas info |
| `GetAtlasSize()` | Get atlas dimensions |
| `AddWayPoint(type, id, x, y)` | Add waypoint |
| `RemoveWayPoint(id)` | Remove waypoint |
| `RegisterAtlasWindow(window)` | Register atlas window |
| `UnregisterAtlasWindow()` | Unregister atlas |
| `GetGuildAreaID(x, y)` | Get guild area |

---

## nonplayer

NPC/monster data from mob_proto.

| Function | Purpose |
|----------|---------|
| `GetEventType(vnum)` | Get NPC event type |
| `GetEventTypeByVID(vid)` | Event type by VID |
| `GetLevelByVID(vid)` | NPC level |
| `GetGradeByVID(vid)` | NPC grade |
| `GetMonsterName(vnum)` | Monster name |
| `LoadNonPlayerData(filename)` | Load mob proto |
| `GetVnumByVID(vid)` | Get VNUM from VID |
| `GetMonsterRaceFlag(vnum)` | Race flags |
| `GetGoldMinByVID(vid)` | Min gold drop |
| `GetGoldMaxByVID(vid)` | Max gold drop |
| `GetExpByVID(vid)` | EXP value |
| `GetMaxHPByVID(vid)` | Max HP |
| `GetDefByVID(vid)` | Defense |
| `GetAIFlagByVID(vid)` | AI flags |
| `GetRaceFlagByVID(vid)` | Race flags by VID |
| `GetImmuneFlagByVID(vid)` | Immune flags |
| `GetStrByVID(vid)` | Strength |
| `GetDexByVID(vid)` | Dexterity |
| `GetConByVID(vid)` | Constitution |
| `GetIntByVID(vid)` | Intelligence |
| `GetDamageRangeMinByVID(vid)` | Min damage |
| `GetDamageRangeMaxByVID(vid)` | Max damage |

---

## event

Quest event manager.

| Function | Purpose |
|----------|---------|
| `RegisterEventSet(filename)` | Register event script |
| `RegisterEventSetFromString(text)` | Register from string |
| `ClearEventSet(eventId)` | Clear event |
| `SetRestrictedCount(eventId, count)` | Set restricted lines |
| `GetEventSetLocalYPosition(eventId)` | Get Y position |
| `AddEventSetLocalYPosition(eventId, y)` | Add Y offset |
| `InsertText(eventId, text, idx)` | Insert text |
| `InsertTextInline(eventId, text, idx, offset)` | Insert inline |
| `UpdateEventSet(eventId, elapsed)` | Update event |
| `RenderEventSet(eventId)` | Render event |
| `SetEventSetWidth(eventId, width)` | Set width |
| `Skip(eventId)` | Skip animation |
| `IsWait(eventId)` | Check waiting for input |
| `EndEventProcess(eventId)` | End processing |
| `SelectAnswer(eventId, answer)` | Select quest answer |
| `GetLineCount(eventId)` | Get line count |
| `SetVisibleStartLine(eventId, line)` | Set scroll start |
| `GetVisibleStartLine(eventId)` | Get scroll start |
| `SetEventHandler(handler)` | Set event handler |
| `SetInterfaceWindow(window)` | Set interface window |
| `SetLeftTimeString(text)` | Set timer text |
| `QuestButtonClick(idx)` | Click quest button |
| `Destroy()` | Destroy event manager |
| `SetVisibleLineCount(eventId, count)` | Set visible lines |
| `GetLineHeight(eventId)` | Get line height |
| `SetYPosition(eventId, y)` | Set Y position |
| `GetProcessedLineCount(eventId)` | Processed lines |
| `AllProcessEventSet(eventId)` | Process all at once |
| `GetTotalLineCount(eventId)` | Total lines |
| `SetFontColor(eventId, r, g, b)` | Set text color |

---

## ime

Input method editor.

| Function | Purpose |
|----------|---------|
| `Enable()` | Enable IME |
| `Disable()` | Disable IME |
| `EnableCaptureInput()` | Capture input |
| `DisableCaptureInput()` | Stop capture |
| `SetMax(max)` | Set max input length |
| `SetUserMax(max)` | Set user max |
| `SetText(text)` | Set text content |
| `GetText()` | Get text content |
| `GetCodePage()` | Get code page |
| `GetCandidateCount()` | IME candidate count |
| `GetCandidate(idx)` | Get candidate text |
| `GetCandidateSelection()` | Get selected candidate |
| `GetReading()` | Get reading text |
| `GetReadingError()` | Get reading error |
| `EnableIME()` | Enable IME mode |
| `DisableIME()` | Disable IME mode |
| `GetInputMode()` | Get input mode |
| `SetInputMode(mode)` | Set input mode |
| `SetNumberMode()` | Numbers only mode |
| `SetStringMode()` | String input mode |
| `AddExceptKey(key)` | Add exception key |
| `ClearExceptKey()` | Clear exception keys |
| `MoveLeft()` | Move cursor left |
| `MoveRight()` | Move cursor right |
| `MoveHome()` | Move to start |
| `MoveEnd()` | Move to end |
| `SetCursorPosition(pos)` | Set cursor position |
| `Delete()` | Delete at cursor |
| `PasteString(text)` | Paste text |
| `PasteBackspace()` | Backspace |
| `PasteReturn()` | Enter key |
| `PasteTextFromClipBoard()` | Paste clipboard |
| `EnablePaste()` | Enable paste |

---

## systemSetting

System configuration and display settings.

| Function | Purpose |
|----------|---------|
| `GetWidth()` | Screen width |
| `GetHeight()` | Screen height |
| `SetInterfaceHandler(handler)` | Set UI handler |
| `DestroyInterfaceHandler()` | Destroy handler |
| `GetResolutionCount()` | Available resolutions |
| `GetFrequencyCount(resIdx)` | Available frequencies |
| `GetCurrentResolution()` | Current resolution |
| `GetResolution(idx)` | Get resolution by index |
| `GetFrequency(resIdx, freqIdx)` | Get frequency |
| `ApplyConfig()` | Apply settings |
| `SetConfig(key, value)` | Set config value |
| `SaveConfig()` | Save to file |
| `GetConfig(key)` | Get config value |
| `SetSaveID(id, flag)` | Set saved login ID |
| `isSaveID()` | Check if ID saved |
| `GetSaveID()` | Get saved ID |
| `GetMusicVolume()` | Music volume |
| `GetSoundVolume()` | Sound volume |
| `SetMusicVolume(vol)` | Set music volume |
| `SetSoundVolumef(vol)` | Set sound volume |
| `IsSoftwareCursor()` | Check SW cursor |
| `SetViewChatFlag(flag)` | Toggle chat visibility |
| `IsViewChat()` | Check chat visible |
| `SetAlwaysShowNameFlag(flag)` | Always show names |
| `IsAlwaysShowName()` | Check show names |
| `SetShowDamageFlag(flag)` | Toggle damage display |
| `IsShowDamage()` | Check damage visible |
| `SetShowSalesTextFlag(flag)` | Toggle sales text |
| `IsShowSalesText()` | Check sales text |
| `GetShadowLevel()` | Shadow quality |
| `SetShadowLevel(level)` | Set shadow quality |
| `IsShowMobAIFlag()` | Check mob AI display |
| `SetShowMobAIFlag(flag)` | Toggle mob AI display |
| `IsShowMobLevel()` | Check mob level display |
| `SetShowMobLevel(flag)` | Toggle mob level |

---

## Smaller Modules

### snd — Sound Manager

| Function | Purpose |
|----------|---------|
| `PlaySound(filename)` | Play 2D sound |
| `PlaySound3D(filename, x, y, z)` | Play 3D sound |
| `PlayMusic(filename)` | Play music track |
| `FadeInMusic(filename, duration)` | Fade in music |
| `FadeOutMusic(filename, duration)` | Fade out music |
| `FadeOutAllMusic()` | Fade out all |
| `StopAllSound()` | Stop everything |
| `SetMusicVolume(vol)` | Set music vol |
| `SetSoundVolume(vol)` | Set sound vol |

### effect — Effect Manager

| Function | Purpose |
|----------|---------|
| `RegisterEffect(effectId, filename)` | Register effect |
| `CreateEffect(effectId, x, y, z)` | Create at position |
| `DeleteEffect(effectId)` | Delete effect |
| `SetPosition(effectId, x, y, z)` | Move effect |
| `Update()` | Update all effects |
| `Render()` | Render all effects |
| `RegisterIndexedFlyData(index, type, filename)` | Register fly data |

### textTail — Text Tail (floating text above characters)

| Function | Purpose |
|----------|---------|
| `RegisterCharacterTextTail(vid, color)` | Register char text |
| `RegisterChatTail(vid, text)` | Register chat bubble |
| `RegisterInfoTail(vid, text)` | Register info text |
| `AttachTitle(vid, title, color)` | Attach title |
| `Clear()` | Clear all text tails |
| `UpdateAllTextTail()` | Update all |
| `Render()` | Render all |
| `ShowCharacterTextTail(vid)` | Show char text |
| `ShowItemTextTail(vid)` | Show item text |
| `HideAllTextTail()` | Hide all |
| `ShowAllTextTail()` | Show all |
| `Pick(x, y)` | Pick text tail at pos |
| `SelectItemName(vid)` | Select item name |
| `EnablePKTitle(flag)` | Toggle PK titles |

### grp — Graphics Rendering

| Function | Purpose |
|----------|---------|
| `SetColor(r, g, b, a)` | Set draw color |
| `RenderLine(x1, y1, x2, y2)` | Draw line |
| `RenderBox(x, y, w, h)` | Draw box outline |
| `RenderBar(x, y, w, h)` | Draw filled rect |
| `RenderGradationBar(x, y, w, h, startColor, endColor)` | Gradient bar |
| `GenerateColor(r, g, b, a)` | Pack color value |
| `GetCursorPosition3d()` | 3D cursor position |
| `SaveScreenShot()` | Save screenshot |
| `SaveScreenShotToPath(path)` | Save to path |
| `SetGamma(r, g, b)` | Set gamma |
| `GetAvailableMemory()` | Available VRAM |

### grpImage — Image Instance Control

| Function | Purpose |
|----------|---------|
| `Generate(filename)` | Create image instance |
| `GenerateExpanded(filename)` | Create expanded instance |
| `Delete()` | Delete instance |
| `Render()` | Render image |
| `SetPosition(x, y)` | Set position |
| `GetWidth()` / `GetHeight()` | Get dimensions |
| `SetScale(x, y)` | Set scale |
| `SetDiffuseColor(r, g, b, a)` | Set tint |
| `SetRenderingRect(l, t, r, b)` | Set rendering rect |
| `SetRotation(degrees)` | Set rotation |

### grpText — Text Instance Control

| Function | Purpose |
|----------|---------|
| `Generate()` | Create text instance |
| `Destroy()` | Destroy instance |
| `SetFontName(font)` | Set font |
| `SetFontColor(r, g, b)` | Set color |
| `SetOutLineColor(r, g, b)` | Set outline color |
| `SetText(text)` | Set content |
| `GetText()` | Get content |
| `GetSize()` | Get pixel dimensions |
| `Render()` | Render text |
| `SetPosition(x, y)` | Set position |
| `SetHorizontalAlign(align)` | Set alignment |
| `SetMax(max)` | Set max chars |
| `SetSecret(flag)` | Password mode |
| `SetOutline(flag)` | Outline mode |
| `ShowCursor()` / `HideCursor()` | Cursor control |

### dbg — Debug

| Function | Purpose |
|----------|---------|
| `LogBox(text)` | Show log box |
| `Trace(text)` | Trace log |
| `Tracen(text)` | Trace with newline |
| `TraceError(text)` | Error log |
| `RegisterExceptionString(text)` | Register exception |

### pack — Pack File Access

| Function | Purpose |
|----------|---------|
| `Exist(filename)` | Check file in pack |
| `Get(filename)` | Get file data |

### fly — Projectile System

| Function | Purpose |
|----------|---------|
| `Update()` | Update projectiles |
| `Render()` | Render projectiles |

### profiler — Performance Profiling

| Function | Purpose |
|----------|---------|
| `Push(name)` | Start profiling block |
| `Pop(name)` | End profiling block |

### gameEvent — Game Event Manager

| Function | Purpose |
|----------|---------|
| `Update()` | Update game events |

### background — World/Map Rendering

| Function | Purpose |
|----------|---------|
| `LoadMap(name)` | Load map |
| `Destroy()` | Destroy map |
| `Initialize()` | Initialize |
| `Update()` | Update world |
| `Render()` | Render world |
| `GetCurrentMapName()` | Current map name |
| `GetHeight(x, y)` | Terrain height |
| `GetPickingPoint()` | Mouse world position |
| `SetEnvironmentData(envId)` | Set weather |
| `RegisterEnvironmentData(envId, filename)` | Register weather |
| `SetVisiblePart(part, flag)` | Toggle render parts |
| `SetShadowLevel(level)` | Shadow quality |
| `GlobalPositionToLocalPosition(x, y)` | World to local coords |
| `GlobalPositionToMapInfo(x, y)` | World pos to map info |
| `SetFogMode(flag)` | Toggle fog |
| `GetFogMode()` | Get fog state |
| `WarpTest(x, y)` | Test warp |
| `EnableSnow(flag)` | Toggle snow |
| `SetTransparentTree(flag)` | Transparent trees |
