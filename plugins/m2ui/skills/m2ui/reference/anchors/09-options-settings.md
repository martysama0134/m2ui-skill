# Anchor 09: Options / Settings Dialog

## What this is + when to use it

A dialog for adjusting client-side preferences: audio volume, graphics quality, control bindings, gameplay toggles. The chrome is a board + multiple labeled rows of widgets (slider bars, radio-button groups, checkboxes, comboboxes) + Apply/Reset/Cancel buttons. Settings persist via the C++ `systemSetting` Python module (`systemSetting.GetMusicVolume`, `systemSetting.SaveSettings`) and `app.SaveSetting` / `constInfo.GET_*` per-key wrappers.

Use this archetype for: system options (graphics, audio, network), gameplay options (camera mode, fog distance, tiling mode), keybind editor, account preferences. Do NOT use this for one-off confirmation dialogs (use `01-simple-dialog`). Do NOT use for character-specific settings that need server roundtrip (those are inventory-style; see `08-inventory-equipment`).

Layer augmentor `16-tabbed-content` when the options span multiple categories (Game / Audio / Display / Controls). Layer `05-feature-gated` for fork-specific options behind `app.ENABLE_*` flags.

## Source

Pattern extracted from `pack/pack/root/uisystemoption.py` and `pack/pack/uiscript/uiscript/systemoptiondialog.py` from a real Metin2 fork (cross-checks `pack/pack/root/uigameoption.py` for the gameplay-options variant). Anchor distills the canonical `OptionDialog` shape — slider for music/sound volume + radio-button groups for camera-distance and fog-mode + radio-button group for software/hardware tiling + Apply button (which exits the game to apply tiling change).

Normalized to current m2ui rules:

- Added `__Initialize()` to centralize var resets (real source already has this — pattern kept verbatim)
- All radio-button callbacks via `SAFE_SetEvent` (Pattern E — fork-augmented helper) or fallback to `ui.__mem_func__` Pattern A. Anchor uses `SAFE_SetEvent` directly per real source; if the fork doesn't provide it, fall back to `Pattern A` (no extra args needed for these zero-arg callbacks).
- Slider-bar `SetEvent` Pattern A — `Slider.SetEvent(self, event)` is 1-arg in `pack/pack/root/ui.py`; `ui.__mem_func__(self.OnChangeMusicVolume)` works directly (the slider passes its position to the callback as the `*args` it produces — verify `Slider.OnUpdate` in the fork's `ui.py`)
- `Destroy()` body preserved with `if self.X:` guards on owned dialogs (`musicListDlg`)
- Stripped `print` debug statements (real source has print on __del__ and Destroy — fork-debug remnants)
- ASCII-only in code AND inline comments

## Uiscript dict

```python
import uiScriptLocale

ROOT_PATH = "d:/ymir work/ui/public/"

window = {
    "name" : "SystemOptionDialog",
    "style" : ("movable", "float",),

    "x" : 0,
    "y" : 0,

    "width" : 305,
    "height" : 300,

    "children" :
    (
        {
            "name" : "board",
            "type" : "board",

            "x" : 0,
            "y" : 0,

            "width" : 305,
            "height" : 300,

            "children" :
            (
                ## Title
                {
                    "name" : "titlebar",
                    "type" : "titlebar",
                    "style" : ("attach",),

                    "x" : 8,
                    "y" : 8,

                    "width" : 284,
                    "color" : "gray",

                    "children" :
                    (
                        {
                            "name" : "titlename", "type" : "text",
                            "x" : 0, "y" : 3,
                            "horizontal_align" : "center",
                            "text_horizontal_align" : "center",
                            "text" : uiScriptLocale.SYSTEMOPTION_TITLE,
                        },
                    ),
                },

                ## Sound volume row
                { "name" : "sound_name", "type" : "text", "x" : 30, "y" : 50, "text" : uiScriptLocale.OPTION_SOUND },
                {
                    "name" : "sound_volume_controller", "type" : "sliderbar",
                    "x" : 110, "y" : 50,
                },

                ## Music volume row
                { "name" : "music_name", "type" : "text", "x" : 30, "y" : 75, "text" : uiScriptLocale.OPTION_MUSIC },
                {
                    "name" : "music_volume_controller", "type" : "sliderbar",
                    "x" : 110, "y" : 75,
                },

                ## Music change button + selected-file display
                {
                    "name" : "bgm_button", "type" : "button",
                    "x" : 20, "y" : 100,
                    "text" : uiScriptLocale.OPTION_MUSIC_CHANGE,
                    "default_image" : ROOT_PATH + "Middle_Button_01.sub",
                    "over_image"    : ROOT_PATH + "Middle_Button_02.sub",
                    "down_image"    : ROOT_PATH + "Middle_Button_03.sub",
                },
                { "name" : "bgm_file", "type" : "text", "x" : 100, "y" : 102, "text" : uiScriptLocale.OPTION_MUSIC_DEFAULT_THEMA },

                ## Camera-distance radio row
                { "name" : "camera_name", "type" : "text", "x" : 30, "y" : 130, "text" : uiScriptLocale.OPTION_CAMERA_MODE },
                {
                    "name" : "camera_short", "type" : "radio_button",
                    "x" : 110, "y" : 130,
                    "default_image" : ROOT_PATH + "Small_Button_01.sub",
                    "over_image"    : ROOT_PATH + "Small_Button_02.sub",
                    "down_image"    : ROOT_PATH + "Small_Button_03.sub",
                    "children" : ( { "name" : "camera_short_text", "type" : "text", "x" : 0, "y" : 0, "all_align" : "center", "text" : uiScriptLocale.OPTION_CAMERA_SHORT }, ),
                },
                {
                    "name" : "camera_long", "type" : "radio_button",
                    "x" : 165, "y" : 130,
                    "default_image" : ROOT_PATH + "Small_Button_01.sub",
                    "over_image"    : ROOT_PATH + "Small_Button_02.sub",
                    "down_image"    : ROOT_PATH + "Small_Button_03.sub",
                    "children" : ( { "name" : "camera_long_text", "type" : "text", "x" : 0, "y" : 0, "all_align" : "center", "text" : uiScriptLocale.OPTION_CAMERA_LONG }, ),
                },

                ## Fog-mode radio row
                { "name" : "fog_name", "type" : "text", "x" : 30, "y" : 160, "text" : uiScriptLocale.OPTION_FOG_MODE },
                {
                    "name" : "fog_off", "type" : "radio_button",
                    "x" : 110, "y" : 160,
                    "default_image" : ROOT_PATH + "Small_Button_01.sub",
                    "over_image"    : ROOT_PATH + "Small_Button_02.sub",
                    "down_image"    : ROOT_PATH + "Small_Button_03.sub",
                    "children" : ( { "name" : "fog_off_text", "type" : "text", "x" : 0, "y" : 0, "all_align" : "center", "text" : uiScriptLocale.OPTION_FOG_OFF }, ),
                },
                {
                    "name" : "fog_on", "type" : "radio_button",
                    "x" : 165, "y" : 160,
                    "default_image" : ROOT_PATH + "Small_Button_01.sub",
                    "over_image"    : ROOT_PATH + "Small_Button_02.sub",
                    "down_image"    : ROOT_PATH + "Small_Button_03.sub",
                    "children" : ( { "name" : "fog_on_text", "type" : "text", "x" : 0, "y" : 0, "all_align" : "center", "text" : uiScriptLocale.OPTION_FOG_ON }, ),
                },

                ## Tiling-mode radio row + Apply
                { "name" : "tiling_name", "type" : "text", "x" : 30, "y" : 200, "text" : uiScriptLocale.OPTION_TILING_MODE },
                {
                    "name" : "tiling_cpu", "type" : "radio_button",
                    "x" : 110, "y" : 200,
                    "default_image" : ROOT_PATH + "Small_Button_01.sub",
                    "over_image"    : ROOT_PATH + "Small_Button_02.sub",
                    "down_image"    : ROOT_PATH + "Small_Button_03.sub",
                    "children" : ( { "name" : "tiling_cpu_text", "type" : "text", "x" : 0, "y" : 0, "all_align" : "center", "text" : "CPU" }, ),
                },
                {
                    "name" : "tiling_gpu", "type" : "radio_button",
                    "x" : 165, "y" : 200,
                    "default_image" : ROOT_PATH + "Small_Button_01.sub",
                    "over_image"    : ROOT_PATH + "Small_Button_02.sub",
                    "down_image"    : ROOT_PATH + "Small_Button_03.sub",
                    "children" : ( { "name" : "tiling_gpu_text", "type" : "text", "x" : 0, "y" : 0, "all_align" : "center", "text" : "GPU" }, ),
                },
                {
                    "name" : "tiling_apply", "type" : "button",
                    "x" : 220, "y" : 200,
                    "text" : uiScriptLocale.OPTION_APPLY,
                    "default_image" : ROOT_PATH + "Middle_Button_01.sub",
                    "over_image"    : ROOT_PATH + "Middle_Button_02.sub",
                    "down_image"    : ROOT_PATH + "Middle_Button_03.sub",
                },
            ),
        },
    ),
}
```

## Root class

```python
import ui
import snd
import systemSetting
import net
import chat
import app
import localeInfo
import constInfo
import musicInfo
import background

import uiSelectMusic


class OptionDialog(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.__Initialize()
        self.__Load()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self):
        self.tilingMode = 0
        self.titleBar = None
        self.changeMusicButton = None
        self.selectMusicFile = None
        self.ctrlMusicVolume = None
        self.ctrlSoundVolume = None
        self.musicListDlg = None
        self.tilingApplyButton = None
        self.cameraModeButtonList = []
        self.fogButtonList = []
        self.tilingModeButtonList = []

    @ui.WindowDestroy
    def Destroy(self):
        self.ClearDictionary()
        if self.musicListDlg:
            self.musicListDlg.Destroy()
            self.musicListDlg = None
        self.__Initialize()

    def __Load(self):
        try:
            scriptLoader = ui.PythonScriptLoader()
            scriptLoader.LoadScriptFile(self, "uiscript/systemoptiondialog.py")
        except:
            import exception
            exception.Abort("OptionDialog.__Load_LoadScript")

        try:
            GetObject = self.GetChild
            self.titleBar = GetObject("titlebar")
            self.selectMusicFile = GetObject("bgm_file")
            self.changeMusicButton = GetObject("bgm_button")
            self.ctrlMusicVolume = GetObject("music_volume_controller")
            self.ctrlSoundVolume = GetObject("sound_volume_controller")
            self.cameraModeButtonList.append(GetObject("camera_short"))
            self.cameraModeButtonList.append(GetObject("camera_long"))
            self.fogButtonList.append(GetObject("fog_off"))
            self.fogButtonList.append(GetObject("fog_on"))
            self.tilingModeButtonList.append(GetObject("tiling_cpu"))
            self.tilingModeButtonList.append(GetObject("tiling_gpu"))
            self.tilingApplyButton = GetObject("tiling_apply")
        except:
            import exception
            exception.Abort("OptionDialog.__Load_BindObject")

        self.SetCenterPosition()

        self.titleBar.SetCloseEvent(ui.__mem_func__(self.Close))

        # Slider events: Slider.SetEvent is 1-arg per ui.py; the slider
        # invokes the callback with the new position passed via *args at
        # the slider's internal dispatch.
        self.ctrlMusicVolume.SetSliderPos(float(systemSetting.GetMusicVolume()))
        self.ctrlMusicVolume.SetEvent(ui.__mem_func__(self.OnChangeMusicVolume))

        self.ctrlSoundVolume.SetSliderPos(float(systemSetting.GetSoundVolume()) / 5.0)
        self.ctrlSoundVolume.SetEvent(ui.__mem_func__(self.OnChangeSoundVolume))

        # Button events: SAFE_SetEvent is fork-augmented (Pattern E). Falls
        # back to ui.__mem_func__ if the fork lacks it.
        self.changeMusicButton.SAFE_SetEvent(self.__OnClickChangeMusicButton)

        self.cameraModeButtonList[0].SAFE_SetEvent(self.__OnClickCameraModeShortButton)
        self.cameraModeButtonList[1].SAFE_SetEvent(self.__OnClickCameraModeLongButton)

        self.fogButtonList[0].SAFE_SetEvent(self.__OnClickFogModeOffButton)
        self.fogButtonList[1].SAFE_SetEvent(self.__OnClickFogModeOnButton)

        self.tilingModeButtonList[0].SAFE_SetEvent(self.__OnClickTilingModeCPUButton)
        self.tilingModeButtonList[1].SAFE_SetEvent(self.__OnClickTilingModeGPUButton)
        self.tilingApplyButton.SAFE_SetEvent(self.__OnClickTilingApplyButton)

        self.__SetCurTilingMode()

        self.__ClickRadioButton(self.fogButtonList, background.GetFogMode())
        self.__ClickRadioButton(self.cameraModeButtonList, constInfo.GET_CAMERA_MAX_DISTANCE_INDEX())

        if musicInfo.fieldMusic == musicInfo.METIN2THEMA:
            self.selectMusicFile.SetText(uiSelectMusic.DEFAULT_THEMA)
        else:
            MUSIC_FILENAME_MAX_LEN = 25
            self.selectMusicFile.SetText(musicInfo.fieldMusic[:MUSIC_FILENAME_MAX_LEN])

    def Open(self):
        self.SetCenterPosition()
        self.SetTop()
        self.Show()

    def Close(self):
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True

    # Helper: select one button in a radio group by index.
    def __ClickRadioButton(self, buttonList, buttonIndex):
        try:
            selButton = buttonList[buttonIndex]
        except IndexError:
            return
        for eachButton in buttonList:
            eachButton.SetUp()
        selButton.Down()

    def __SetTilingMode(self, index):
        self.__ClickRadioButton(self.tilingModeButtonList, index)
        self.tilingMode = index

    def __SetCurTilingMode(self):
        # Read current from C++ binding; default 0 (CPU) if absent.
        try:
            cur = background.IsSoftwareTiling()
            if cur:
                self.__SetTilingMode(0)
            else:
                self.__SetTilingMode(1)
        except AttributeError:
            self.__SetTilingMode(0)

    # Sound / music callbacks (slider passes new pos via *args)
    def OnChangeMusicVolume(self, value):
        systemSetting.SetMusicVolume(value)
        snd.SetMusicVolume(value * net.GetField())

    def OnChangeSoundVolume(self, value):
        systemSetting.SetSoundVolume(value * 5.0)
        snd.SetSoundMaxNum(value * 5.0)

    # Camera-distance callbacks
    def __OnClickCameraModeShortButton(self):
        constInfo.SET_CAMERA_MAX_DISTANCE_INDEX(0)
        self.__ClickRadioButton(self.cameraModeButtonList, 0)

    def __OnClickCameraModeLongButton(self):
        constInfo.SET_CAMERA_MAX_DISTANCE_INDEX(1)
        self.__ClickRadioButton(self.cameraModeButtonList, 1)

    # Fog callbacks
    def __OnClickFogModeOffButton(self):
        background.SetFogMode(0)
        self.__ClickRadioButton(self.fogButtonList, 0)

    def __OnClickFogModeOnButton(self):
        background.SetFogMode(1)
        self.__ClickRadioButton(self.fogButtonList, 1)

    # Tiling callbacks
    def __OnClickTilingModeCPUButton(self):
        self.__NotifyChatLine(localeInfo.SYSTEM_OPTION_CPU_TILING_1)
        self.__SetTilingMode(0)

    def __OnClickTilingModeGPUButton(self):
        self.__NotifyChatLine(localeInfo.SYSTEM_OPTION_GPU_TILING_1)
        self.__SetTilingMode(1)

    def __OnClickTilingApplyButton(self):
        self.__NotifyChatLine(localeInfo.SYSTEM_OPTION_TILING_EXIT)
        if 0 == self.tilingMode:
            background.EnableSoftwareTiling(1)
        else:
            background.EnableSoftwareTiling(0)
        # Tiling mode change requires client restart (engine binding).
        net.ExitGame()

    # Music selection callbacks
    def __OnClickChangeMusicButton(self):
        if not self.musicListDlg:
            self.musicListDlg = uiSelectMusic.FileListDialog()
            self.musicListDlg.SAFE_SetSelectEvent(self.__OnChangeMusic)
        self.musicListDlg.Open()

    def __OnChangeMusic(self, fileName):
        if fileName == uiSelectMusic.DEFAULT_THEMA:
            musicInfo.fieldMusic = musicInfo.METIN2THEMA
            self.selectMusicFile.SetText(uiSelectMusic.DEFAULT_THEMA)
        else:
            musicInfo.fieldMusic = fileName
            MUSIC_FILENAME_MAX_LEN = 25
            self.selectMusicFile.SetText(fileName[:MUSIC_FILENAME_MAX_LEN])

    def __NotifyChatLine(self, line):
        chat.AppendChat(chat.CHAT_TYPE_INFO, line)
```

## Locale entries

Append to `locale_interface.txt`:

```
SYSTEMOPTION_TITLE	System Settings
OPTION_SOUND	Sound
OPTION_MUSIC	Music
OPTION_MUSIC_CHANGE	Change
OPTION_MUSIC_DEFAULT_THEMA	Default
OPTION_CAMERA_MODE	Camera
OPTION_CAMERA_SHORT	Near
OPTION_CAMERA_LONG	Far
OPTION_FOG_MODE	Fog
OPTION_FOG_OFF	Off
OPTION_FOG_ON	On
OPTION_TILING_MODE	Tiling
OPTION_APPLY	Apply
```

Append to `locale_game.txt`:

```
SYSTEM_OPTION_CPU_TILING_1	Switching to software tiling.
SYSTEM_OPTION_GPU_TILING_1	Switching to hardware tiling.
SYSTEM_OPTION_TILING_EXIT	Tiling change requires client restart. Exiting...
```

## interfacemodule.py integration snippet

```python
import uiSystemOption

class Interface(object):

    def __init__(self):
        self.dlgSystemOption = None

    def MakeInterface(self):
        # ... other window creation ...
        # Note: Options dialogs are often constructed lazily on first
        # toggle to save startup memory. See integration.md Variation 2.
        pass

    def __DestroyDialogs(self):
        if self.dlgSystemOption:
            self.dlgSystemOption.Destroy()
            self.dlgSystemOption = None

    def HideAllWindows(self):
        if self.dlgSystemOption:
            self.dlgSystemOption.Close()

    def ToggleSystemOptionDialog(self):
        if not self.dlgSystemOption:
            self.dlgSystemOption = uiSystemOption.OptionDialog()
        if self.dlgSystemOption.IsShow():
            self.dlgSystemOption.Close()
        else:
            self.dlgSystemOption.Open()
```

## Common variations

1. **Multi-tab options window** — split sound/music/music-change into a "Audio" tab, camera/fog/tiling into a "Display" tab, etc. Layer augmentor `16-tabbed-content` for the radio-group + Show/Hide content swap. Each tab's content is a child window; the parent options dialog's `LoadDialog` creates each tab content and `OnTabChange` toggles visibility.
2. **Checkbox row** — replace a 2-state radio_button pair with a single `checkbox` widget. Class side: `self.chkMyOption.SetCheckedEvent(ui.__mem_func__(self.OnToggleMyOption))`; in callback, `value = self.chkMyOption.IsChecked()`. Smaller footprint, less explicit on/off labels.
3. **Combobox dropdown** — for selecting from > 2 enumerated values (resolution, language). `ComboBox.AppendItem(label, value)` adds entries; `ComboBox.SetSelectedIndex(idx)` sets default; `ComboBox.SetSelectEvent(ui.__mem_func__(self.OnSelectResolution))` wires the change. ComboBox dropdown direction is set by uiscript `"direction" : "up"|"down"` — see widgets.md ComboBox subsection.
4. **Settings persistence on close** — add `def Close(self): self.SaveSettings(); self.Hide()` and a `SaveSettings` method that calls `app.SaveSetting` / `systemSetting.SaveSettings()`. Real source defers persistence to `__OnClickTilingApplyButton` (for tiling) and inside each callback (for volumes); centralizing on Close is cleaner.
5. **Reset-to-default button** — add a Reset button in uiscript and a callback that calls each `__OnClick*Button` with the default index, OR calls `systemSetting.ResetToDefaults()` if the binding exists.

## Don't copy these obsolete bits

- Real source has `print(" -------------------------------------- DESTROY SYSTEM OPTION DIALOG")` in Destroy and `__del__`. These are fork-debug remnants — strip them. Use `dbg.TraceError` if you genuinely need lifecycle logging.
- Real source has commented-out shadow-quality slider (`#self.ctrlShadowQuality = GetObject("shadow_bar")`). Anchor strips the dead code — if shadow quality is an option in your fork, wire the slider live; otherwise remove the row from uiscript entirely.
- Real source uses `self.X = 0` (integer) for widget refs in `__Initialize()`. Anchor uses `None` for consistency with other anchors and the `if self.X:` guard pattern.
- Real source has both a `fogModeButtonList` (3-level fog) and a `fogButtonList` (2-state fog) gated by `app.__BL_FOG_FIX__`. Anchor keeps only the 2-state form (more common and simpler); 3-level fog is a fork variation, layer `05-feature-gated` if needed.
- Real source's slider callbacks read `self.ctrlMusicVolume.GetSliderPos()` AND receive the value as a callback arg. Pick one — anchor uses the callback arg (cleaner; avoids a redundant getter call).
