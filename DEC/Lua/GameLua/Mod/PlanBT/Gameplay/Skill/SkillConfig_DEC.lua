local SkillCDDefine = require("GameLua.Mod.Library.GamePlay.Skill.SkillCD.SkillCDDefine")
local ESkillIconStatus = import("ESkillIconStatus")
local Config = {
  [4900011] = {
    SkillCDParams = {
      [1] = {
        SkillCDClass = "GameLua.Mod.Library.GamePlay.Skill.SkillCD.SkillCD_Time",
        Params = {nCD = 2}
      },
      [2] = {
        SkillCDClass = "GameLua.Mod.Library.GamePlay.Skill.SkillCD.SkillCD_Time",
        Params = {nCD = 3}
      }
    },
    SkillWidgetParams = {
      CanvasVisibleConfigKey = "SkillBtnShowConfig",
      ActiveCDIndex = 1,
      CDIndex = 2,
      CDType = SkillCDDefine.ECDType.CDT_Timer,
      CDTypeStr = "%.f",
      WidgetPath = "/Game/Mod/PlanBT/BluePrints/UI/SkillButton/CommonSkillButton_Activable_UIBP.CommonSkillButton_Activable_UIBP",
      WidgetClass = "GameLua.Mod.Library.Client.UI.SkillButton.UseBroomSkillButton",
      MountData = {
        MountName = "CanvasPanel_Skill3"
      },
      SkillIcon = {
        [ESkillIconStatus.IconBtnNormal] = "/Game/Library/Res/Vehicles/Broom/Arts/UI/Atlas/Frames/ZD_Icon_Available_01_png.ZD_Icon_Available_01_png",
        [ESkillIconStatus.IconBtnActive] = "/Game/Library/Res/Vehicles/Broom/Arts/UI/Atlas/Frames/ZD_Icon_Available_png.ZD_Icon_Available_png",
        [ESkillIconStatus.IconBtnInCD] = "/Game/Library/Res/Vehicles/Broom/Arts/UI/Atlas/Frames/ZD_Icon_Available_01_png.ZD_Icon_Available_01_png"
      }
    }
  },
  [4300952] = {
    SkillWidgetParams = {
      WidgetPath = "/Game/Library/Res/SkillsCommon/UICommon/BluePrints/UI/SkillButton/CommonSkillButton_UIBP.CommonSkillButton_UIBP",
      WidgetClass = "GameLua.Mod.PlanBT.Client.UI.SkillButton.TrapSkillButtonUI",
      MountData = {
        AnchorsData = {
          Minimum = {0, 0},
          Maximum = {0, 0}
        },
        SizeData = FVector2D(68, 68),
        MountName = "CanvasPanel_Skill2"
      },
      SkillIcon = {
        [ESkillIconStatus.IconBtnNormal] = "/Game/Mod/PlanBT/Arts/UI/Atlas/Frames/ZD_Icon_Trap_png.ZD_Icon_Trap_png",
        [ESkillIconStatus.IconBtnInCD] = "/Game/Mod/PlanBT/Arts/UI/Atlas/Frames/ZD_Icon_Trap_png.ZD_Icon_Trap_png",
        [ESkillIconStatus.IconBtnActive] = "/Game/Mod/PlanBT/Arts/UI/Atlas/Frames/ZD_Icon_Trap_png.ZD_Icon_Trap_png"
      }
    }
  },
  [4300953] = {
    SkillCDParams = {
      [1] = {
        SkillCDClass = "GameLua.Mod.Library.GamePlay.Skill.SkillCD.SkillCD_CastEnergyWithCount",
        Params = {
          nInitEnergy = 15,
          nMaxEnergy = 15,
          nDeletaEnergy = 2,
          nMaxCount = 2,
          nInitCount = 2
        }
      }
    },
    SkillWidgetParams = {
      CDType = SkillCDDefine.ECDType.CDT_Timer,
      CDTypeStr = "%.fs",
      WidgetPath = "/Game/Library/Res/SkillsCommon/UICommon/BluePrints/UI/SkillButton/CommonSkillButton_UIBP.CommonSkillButton_UIBP",
      WidgetClass = "GameLua.Mod.Library.Client.UI.SkillButton.DashSkillButton",
      UseCountIndex = 1,
      bShowUseCountCD = true,
      MountData = {
        AnchorsData = {
          Minimum = {0, 0},
          Maximum = {0, 0}
        },
        SizeData = FVector2D(68, 68),
        MountName = "CanvasPanel_Skill1"
      },
      SkillIcon = {
        [ESkillIconStatus.IconBtnNormal] = "/Game/Mod/PlanBT/Arts/UI/NoAtlas/BT_Icon_Propeller.BT_Icon_Propeller"
      }
    }
  }
}
return Config
