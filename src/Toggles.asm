// Toggles.asm
if !{defined __TOGGLES__} {
define __TOGGLES__()
print "included Toggles.asm\n"

include "Color.asm"
include "Menu.asm"
include "MIDI.asm"
include "OS.asm"
include "SRAM.asm"
include "Stages.asm"

scope Toggles {

    // @ Description
    // Allows function 
    macro guard(entry_address, exit_address) {
        addiu   sp, sp,-0x0008              // allocate stack space
        sw      at, 0x0004(sp)              // save at
        li      at, {entry_address}         // ~
        lw      at, 0x0004(at)              // at = is_enabled
        bnez    at, pc() + 24               // if (is_enabled), _continue
        nop

        // _end:
        lw      at, 0x0004(sp)              // restore at
        addiu   sp, sp, 0x0008              // deallocate stack space

        // foor hook vs. function
        if ({exit_address} == 0x00000000) {
            jr      ra
        } else {
            j       {exit_address}
        }
        nop

        // _continue:
        lw      at, 0x0004(sp)              // restore at
        addiu   sp, sp, 0x0008              // deallocate stack space
    }

    // @ Description
    // This patch disables functionality on the OPTION screen.
    scope disable_options_functionality_: {
        OS.patch_start(0x0012060C, 0x80132E5C)
        jal     disable_options_functionality_
        addiu   t7, t7, 0x36EC              // original line 1
        OS.patch_end()

        li      t9, normal_options          // t9 = normal options flag
        lbu     t9, 0x0000(t9)              // t9 = 1 if custom toggles
        beqz    t9, _custom                 // if custom toggles, skip
        nop
        jr      ra                          // return as normal
        lw      t9, 0x0000(t7)              // original line 2

        _custom:
        lw      ra, 0x0014(sp)              // ra = original ra
        jr      ra                          // exit original routine
        addiu   sp, sp, 0x0038              // restore stack
    }

    // @ Description
    // The following patches enable a new button on the Mode Select menu
    scope add_mode_select_remix_button_: {
        // Adjust max index from 3 to 4
        OS.patch_start(0x11D942, 0x801329B2)
        dh      0x0004
        OS.patch_end()
        OS.patch_start(0x11D962, 0x801329D2)
        dh      0x0004
        OS.patch_end()
        OS.patch_start(0x11D866, 0x801328D6)
        dh      0x0004
        OS.patch_end()

        // Adjust X position by 19 for all buttons
        OS.patch_start(0x11CB30, 0x80131BA0)
        lui     at, 0x433C              // original was 0x4329
        OS.patch_end()
        OS.patch_start(0x11CB8C, 0x80131BFC)
        lui     at, 0x433C              // original was 0x4329
        OS.patch_end()
        OS.patch_start(0x11CC50, 0x80131CC0)
        lui     at, 0x4313              // original was 0x4300
        OS.patch_end()
        OS.patch_start(0x11CCB0, 0x80131D20)
        lui     at, 0x4313              // original was 0x4300
        OS.patch_end()
        OS.patch_start(0x11CD74, 0x80131DE4)
        lui     at, 0x42D4              // original was 0x42AE
        OS.patch_end()
        OS.patch_start(0x11CDD4, 0x80131E44)
        lui     at, 0x42D4              // original was 0x42AE
        OS.patch_end()
        OS.patch_start(0x11CE98, 0x80131F08)
        lui     at, 0x4282              // original was 0x4238
        OS.patch_end()
        OS.patch_start(0x11CEF8, 0x80131F68)
        lui     at, 0x4282              // original was 0x4238
        OS.patch_end()

        // Adjust X position by 12 for all button labels
        OS.patch_start(0x11CFA4, 0x80132014)
        lui     at, 0x436C              // original was 0x4360
        OS.patch_end()
        OS.patch_start(0x11CFFC, 0x8013206C)
        lui     at, 0x4343              // original was 0x4337
        OS.patch_end()
        OS.patch_start(0x11D054, 0x801320C4)
        lui     at, 0x431A              // original was 0x430E
        OS.patch_end()
        OS.patch_start(0x11D0AC, 0x8013211C)
        lui     at, 0x42E4              // original was 0x42CC
        OS.patch_end()

    }

    // @ Description
    // Flag to indicate if we should show the custom toggles or the normal options page
    // TRUE = normal options, FALSE = custom toggles
    normal_options:
    db OS.TRUE
    OS.align(4)

    // @ Description
    // Strings for the settings submenu headers
    string_remix_settings:; String.insert("Remix Settings")
    string_stage_settings:; String.insert("Stage Settings")
    string_music_settings:; String.insert("Music Settings")

    // @ Description
    // Pointer to current submenu header string
    page_title_pointer:
    dw 0x00000000

    // @ Description
    // Pointer to current profile string
    profile_pointer:
    dw 0x00000000

    // @ Description
    // Helper routine to set the settings button's visibility based on the selected button index
    scope set_settings_button_display_: {
        lui     t0, 0x8013               // t1 = index
        lw      t1, 0x2C88(t0)           // ~
        lli     t2, 0x0004               // t2 = 4 (index of new button)
        lw      t3, 0x2CA8(t0)           // t3 = object struct of new button, unselected
        lw      t4, 0x2CAC(t0)           // t4 = object struct of new button, selected
        lli     t5, 0x0001               // t5 = 1 (display off)
        sw      t5, 0x007C(t3)           // turn of display
        sw      t5, 0x007C(t4)           // turn of display
        beql    t1, t2, pc() + 12        // based on the index, turn the appropriate button on
        sw      r0, 0x007C(t4)
        sw      r0, 0x007C(t3)

        jr      ra
        nop
    }

    // @ Description
    // Shrinks the buttons and text on the mode select screen to make a 5th button fit
    scope rescale_mode_select_buttons_: {
        constant SCALE(0x3F68)
        // Down scroll
        OS.patch_start(0x11D984, 0x801329F4)
        jal     rescale_mode_select_buttons_
        nop
        OS.patch_end()
        // Up scroll
        OS.patch_start(0x11D89C, 0x8013290C)
        jal     rescale_mode_select_buttons_
        nop
        OS.patch_end()

        addiu   sp, sp,-0x0030              // allocate stack space
        sw      ra, 0x0004(sp)              // ~

        jal     0x801324D8                  // original line 1
        nop                                 // original line 2

        jal     rescale_mode_select_buttons_._rescale
        nop

        jal     set_settings_button_display_
        nop

        lw      ra, 0x0004(sp)              // restore ra
        addiu   sp, sp, 0x0030              // deallocate stack space

        jr      ra
        nop

        _rescale:
        li      t0, Render.GROUP_TABLE      // t0 = group pointer table
        lw      t0, 0x000C(t0)              // t0 = group 3's first object address
        lui     t1, SCALE                   // t1 = scale

        _loop:
        lw      t2, 0x0074(t0)              // t2 = image struct
        sw      t1, 0x0018(t2)              // set X scale
        sw      t1, 0x001C(t2)              // set Y scale
        lw      t0, 0x0004(t0)              // t0 = next object
        bnez    t0, _loop                   // if there is a next object, loop
        nop                                 // otherwise we're done

        jr      ra
        nop
    }

    // @ Description
    // Overwrites the original routine to allow a 5th button to be used when A/Start is pressed on Mode Select screen.
    scope mode_select_screen_change_: {
        OS.patch_start(0x11D668, 0x801326D8)
        // v0 = index of selected button
        beqzl   v0, _change
        addiu   t5, r0, 0x0008              // 1P Game Mode menu
        lli     at, 0x0001
        beql    v0, at, _change
        addiu   t5, r0, 0x0009              // VS Game Mode menu
        lli     at, 0x0002
        beql    v0, at, _change
        addiu   t5, r0, 0x0039              // Options
        lli     at, 0x0003
        beql    v0, at, _change
        addiu   t5, r0, 0x003A              // Data
        lli     at, 0x0004
        beql    v0, at, _change
        addiu   t5, r0, 0x0039              // Settings

        // probably not necessary, but a catch-all
        j       0x80132A00
        lw      ra, 0x0014(sp)

        _change:
        sltiu   at, at, 0x0004              // 0 if custom options should be displayed
        li      v1, normal_options          // v1 = normal options flag
        sb      at, 0x0000(v1)              // set normal options flag
        li      v1, Global.current_screen
        lbu     t4, 0x0000(v1)              // t4 = current screen
        sb      t4, 0x0001(v1)              // set previous screen to current value
        sb      t5, 0x0000(v1)              // set next screen
        jal     0x800269C0                  // play sound
        addiu   a0, r0, 0x009E
        jal     0x80005C74
        nop
        j       0x80132A00
        lw      ra, 0x0014(sp)
        OS.patch_end()
    }

    // @ Description
    // Sets the correct index when coming from options
    OS.patch_start(0x11D4F8, 0x80132568)
    beq     v0, at, 0x801325C0              // original line 1, altered to jump to 0x801325C0
    lli     t8, 0x0000                      // t8 = 0 (index)
    lli     at, 0x0009                      // original line 2
    beq     v0, at, 0x801325C0              // original line 3, altered to jump to 0x801325C0
    lli     t8, 0x0001                      // t8 = 1 (index)
    lli     at, 0x0039                      // original line 5
    beq     v0, at, _options                // original line 6, altered to jump to _options
    lli     t8, 0x0002                      // t8 = 1 (index)
    lli     at, 0x003A                      // original line 8
    beq     v0, at, 0x801325C0              // original line 9, altered to jump to 0x801325C0
    lli     t8, 0x0003                      // t8 = 1 (index)
    b       0x801325C0                      // original line 11, altered to jump to 0x801325C0
    lli     t8, 0x0000                      // t8 = 0 (index)
    _options:
    li      at, normal_options              // at = normal options flag
    lbu     at, 0x0000(at)                  // ~
    beqzl   at, 0x801325C0                  // if normal options flag was false,
    lli     t8, 0x0004                      // then use new button index
    b       0x801325C0                      // continue to where t8 is stored as index
    nop
    OS.patch_end()

    // @ Description
    // Creates the custom objects for the mode select screen (5th button)
    scope mode_select_setup_: {
        constant SETTINGS_OFFSET(0x9748)
        constant SETTINGS_OFFSET_SELECTED(0x9080)
        constant SETTINGS_LABEL_OFFSET(0x99B0)

        addiu   sp, sp,-0x0030              // allocate stack space
        sw      ra, 0x0004(sp)              // ~

        // Render unselected icon
        Render.draw_texture_at_offset(1, 3, 0x80132D6C, SETTINGS_OFFSET, Render.NOOP, 0x41C00000, 0x432E0000, 0x969696FF, 0x00000000, 0x3F800000)
        lui     t0, 0x8013
        sw      v0, 0x2CA8(t0)              // store object pointer in free memory
        Render.draw_texture_at_offset(1, 3, 0x80132D6C, SETTINGS_OFFSET_SELECTED, Render.NOOP, 0x41C00000, 0x432E0000, 0xFFFFFFFF, 0x00000000, 0x3F800000)
        lui     t0, 0x8013
        sw      v0, 0x2CAC(t0)              // store object pointer in free memory
        Render.draw_texture_at_offset(1, 3, 0x80132D6C, SETTINGS_LABEL_OFFSET, Render.NOOP, 0x42900000, 0x43470000, 0xFF0000FF, 0x00000000, 0x3F800000)

        // rescale all the buttons on load
        jal     rescale_mode_select_buttons_._rescale
        nop

        // update display state of each new button icon
        jal     set_settings_button_display_
        nop

        lw      ra, 0x0004(sp)              // restore ra
        addiu   sp, sp, 0x0030              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Increases the available object heap space on the options screen.
    // This is necessary to support when there are lots of long strings.
    // Can probably reduce how much is added, but shouldn't hurt anything.
    OS.patch_start(0x120EE0, 0x80134944)
    dw      0x0000EA60 + 0x2000                 // pad object heap space (0x0000EA60 is original amount)
    OS.patch_end()

    // @ Description
    // Sets up the custom objects for the custom settings menu
    scope setup_: {
        addiu   sp, sp,-0x0030              // allocate stack space
        sw      ra, 0x0004(sp)              // ~

        li      t9, normal_options          // t9 = normal options flag
        lbu     t9, 0x0000(t9)              // t9 = 0 if custom toggles
        bnez    t9, _end                    // skip if not custom
        nop

        Render.load_font()
        Render.load_file(0x4E, Render.file_pointer_1)                 // load option images
        Render.load_file(File.REMIX_MENU_BG, Render.file_pointer_2)   // load remix menu bg
        Render.load_file(0xC5, Render.file_pointer_3)                 // load button images into file_pointer_3

        Render.draw_rectangle(3, 0, 10, 10, 300, 220, 0x000000FF, OS.FALSE)

        Render.draw_texture_at_offset(3, 12, Render.file_pointer_1, 0xB40, Render.NOOP, 0x41C00000, 0x41880000, 0x5F5846FF, 0x00000000, 0x3F800000)
        Render.draw_rectangle(3, 12, 43, 24, 60, 16, 0x000000FF, OS.FALSE)
        Render.draw_string(3, 12, settings, Render.NOOP, 0x42320000, 0x41E40000, 0x5F5846FF, 0x3F600000, Render.alignment.LEFT)
        Render.draw_string_pointer(3, 12, page_title_pointer, Render.update_live_string_, 0x43900000, 0x41A80000, 0xF2C70DFF, 0x3FB00000, Render.alignment.RIGHT)
        Render.draw_texture_at_offset(3, 12, Render.file_pointer_3, Render.file_c5_offsets.R, Render.NOOP, 0x43830000, 0x42180000, 0x848484FF, 0x303030FF, 0x3F700000)
        Render.draw_texture_at_offset(3, 12, 0x801338B0, 0xDD90, Render.NOOP, 0x438C0000, 0x42240000, 0xFFAE00FF, 0x00000000, 0x3F2F0000)

        Render.draw_texture_at_offset(3, 13, Render.file_pointer_2, 0x20718, Render.NOOP, 0x41200000, 0x41200000, 0xFFFFFFFF, 0x00000000, 0x3F800000)
        Render.draw_string(3, 13, current_profile, Render.NOOP, 0x432D0000, 0x434D0000, 0xFFFFFFFF, Render.FONTSIZE_DEFAULT, Render.alignment.RIGHT)
        Render.draw_string_pointer(3, 13, profile_pointer, Render.update_live_string_, 0x43530000, 0x434D0000, 0xFFFFFFFF, Render.FONTSIZE_DEFAULT, Render.alignment.CENTER)

        Render.draw_string(3, 14, toggles_note_line_1, Render.NOOP, 0x43200000, 0x432E0000, 0xFFFFFFFF, Render.FONTSIZE_DEFAULT, Render.alignment.CENTER)
        Render.draw_string(3, 14, toggles_note_line_2, Render.NOOP, 0x43200000, 0x433C0000, 0xFFFFFFFF, Render.FONTSIZE_DEFAULT, Render.alignment.CENTER)
        Render.draw_texture_at_offset(3, 14, Render.file_pointer_3, Render.file_c5_offsets.A, Render.NOOP, 0x42B20000, 0x432E0000, 0x50A8FFFF, 0x0010FFFF, 0x3F800000)

        li      a0, info                    // a0 - info
        sw      r0, 0x0008(a0)              // clear cursor object reference on page load
        sw      r0, 0x000C(a0)              // reset cursor to top
        jal     Menu.draw_                  // draw menu
        nop

        Render.register_routine(run_)

        _end:
        lw      ra, 0x0004(sp)              // restore ra
        addiu   sp, sp, 0x0030              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Runs every frame to correctly update the menu
    scope run_: {
        OS.save_registers()

        li      a0, info
        jal     Menu.update_                // check for updates
        nop

        li      t0, info                    // t0 - address of info
        lw      t1, 0x0000(t0)              // t1 - address of head
        li      t2, head_super_menu         // t2 - address of head_super_menu
        bne     t1, t2, _check_b            // if (not in super menu), skip
        nop                                 //

        jal     get_current_profile_        // v0 - current profile
        nop
        li      a2, string_table_profile    // a2 - profile string table address
        sll     v1, v0, 0x0002              // v1 - offset to profile string address
        addu    a2, a2, v1                  // a2 - address of string address
        lw      a2, 0x0000(a2)              // a2 - address of string
        li      t0, profile_pointer         // t0 = profile_pointer
        sw      a2, 0x0000(t0)              // save updated address

        // draw toggles note
        li      a0, info                    // a0 - address of info
        lw      t1, 0x000C(a0)              // t1 - cursor... 0 if Load Profile is selected
        lli     a1, 0x0001                  // a1 = 1 (display off)
        bnez    t1, _set_notes_display      // if (Load Profile is not selected), then don't display it
        nop
        or      s0, v0, r0                  // s0 = current profile
        jal     Menu.get_selected_entry_    // v0 = selected entry
        nop
        lw      t0, 0x0004(v0)              // t0 = entry.current_value
        beq     t0, s0, _set_notes_display  // if (current profile is not the selected profile), then don't display it
        nop
        li      t0, notes_blink_timer
        lw      t1, 0x0000(t0)              // t0 = current blink timer value
        addiu   t1, t1, 0x0001              // increment timer
        sw      t1, 0x0000(t0)              // ~
        lli     t2, 0x001E                  // t2 = 0x1E
        sltu    a1, t2, t1                  // if timer is less than 0x1E, then show it: a1 = 0 (display on)
        sltiu   t2, t1, 0x0028              // reset timer if we reach 0x28
        beqzl   t2, _set_notes_display
        sw      r0, 0x0000(t0)

        _set_notes_display:
        jal     Render.toggle_group_display_
        lli     a0, 14                      // a0 = group

        // check for exit
        _check_b:
        lli     a0, Joypad.B                // a0 - button_mask
        lli     a1, 000069                  // a1 - whatever you like!
        lli     a2, Joypad.PRESSED          // a2 - type
        jal     Joypad.check_buttons_all_   // check if B pressed
        nop
        beqz    v0, _end                    // nop
        nop
        li      a0, info                    // a0 = address of info
        lw      t1, 0x0000(a0)              // t1 = address of head
        li      t2, head_super_menu         // t2 = address of head_super_menu
        beq     t1, t2, _exit_super_menu    // if (in super menu), exit
        nop                                 // else, exit sub menu

        // restore cursor when returning from sub menu
        li      t2, head_remix_settings     // t2 = head_remix_settings
        beql    t1, t2, _exit_sub_menu      // if (returning from remix settings)
        ori     t0, r0, 0x0001              // then set cursor accordingly
        li      t2, head_music_settings     // t2 = head_music_settings
        beql    t1, t2, _exit_sub_menu      // if (returning from music settings)
        ori     t0, r0, 0x0002              // then set cursor accordingly
        ori     t0, r0, 0x0003              // if (returning from random stage settings) then set cursor accordingly

        _exit_sub_menu:
        jal     Menu.get_selected_entry_    // v0 = selected entry
        nop
        li      t1, info                    // t1 = address of info
        sw      t0, 0x000C(t1)              // restore cursor
        jal     set_info_1_                 // bring up super menu
        nop

        b       _end                        // end menu execution
        nop

        _exit_super_menu:
        jal     save_                       // save toggles
        nop
        lli     a0, 0x0007                  // a0 - screen_id (main menu)
        jal     Menu.change_screen_         // exit to main menu
        nop

        _end:
        OS.restore_registers()
        jr      ra
        nop

        notes_blink_timer:
        dw 0x00000000
    }
    
    // @ Description
    // Save toggles to SRAM
    scope save_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      a0, 0x0004(sp)              // ~
        sw      a1, 0x0008(sp)              // ~
        sw      a2, 0x000C(sp)              // ~
        sw      t0, 0x0010(sp)              // ~
        sw      ra, 0x0014(sp)              // save registers

        li      a0, head_remix_settings     // a0 - address of head
        li      a1, block_misc              // a1 - address of block
        jal     Menu.export_                // export data
        nop
        li      a0, block_misc              // ~
        jal     SRAM.save_                  // save data
        nop

        li      a0, head_music_settings     // a0 - address of head
        li      a1, block_music             // a1 - address of block
        jal     Menu.export_                // export data
        nop
        li      a0, block_music             // ~
        jal     SRAM.save_                  // save data
        nop

        li      a0, head_stage_settings
        li      a1, block_stages            // a1 - address of block
        jal     Menu.export_                // export data
        nop
        li      a0, block_stages            // ~
        jal     SRAM.save_                  // save data
        nop
    
        jal     SRAM.mark_saved_            // mark save file present
        nop

        lw      a0, 0x0004(sp)              // ~
        lw      a1, 0x0008(sp)              // ~
        lw      a2, 0x000C(sp)              // ~
        lw      t0, 0x0010(sp)              // ~
        lw      ra, 0x0014(sp)              // save registers
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    // @ Description
    // Loads toggles from SRAM
    scope load_: {
        addiu   sp, sp,-0x0018              // allocate stack space
        sw      a0, 0x0004(sp)              // ~
        sw      a1, 0x0008(sp)              // ~
        sw      a2, 0x000C(sp)              // ~
        sw      t0, 0x0010(sp)              // ~
        sw      ra, 0x0014(sp)              // save registers

        li      a0, block_misc              // a0 - address of block (misc)
        jal     SRAM.load_                  // load data
        nop
        li      a0, head_remix_settings     // a0 - address of head
        li      a1, block_misc              // a1 - address of block
        jal     Menu.import_
        nop

        li      a0, block_music             // a0 - address of block (music)
        jal     SRAM.load_                  // load data
        nop
        li      a0, head_music_settings     // a0 - address of head 
        li      a1, block_music             // a1 - address of block
        jal     Menu.import_
        nop

        li      a0, block_stages            // a0 - address of block (stages)
        jal     SRAM.load_                  // load data
        nop
        li      a0, head_stage_settings
        li      a1, block_stages            // a1 - address of block
        jal     Menu.import_
        nop

        lw      a0, 0x0004(sp)              // ~
        lw      a1, 0x0008(sp)              // ~
        lw      a2, 0x000C(sp)              // ~
        lw      t0, 0x0010(sp)              // ~
        lw      ra, 0x0014(sp)              // save registers
        addiu   sp, sp, 0x0018              // deallocate stack space
        jr      ra                          // return
        nop
    }

    macro set_info_head(address_of_head, hide_bg_image) {
        // a0 = address of info()
        // v0 = selected entry
        addiu   sp, sp,-0x0010              // allocate stack space
        sw      t0, 0x0004(sp)              // save t0
        sw      t1, 0x0008(sp)              // save t1
        sw      ra, 0x000C(sp)              // save ra

        li      t0, info                    // t0 = info
        li      t1, {address_of_head}       // t1 = address of head
        sw      t1, 0x0000(t0)              // update info->head
        if {hide_bg_image} == OS.TRUE {
            sw      r0, 0x000C(t0)          // update info.selection on sub menus
        }
        lw      a1, 0x0018(t0)              // a1 = 1st displayed currently
        sw      t1, 0x0018(t0)              // update info->1st displayed
        sw      t1, 0x001C(t0)              // update info->last displayed
        li      t0, page_title_pointer      // t0 = page_title pointer
        if {hide_bg_image} == OS.TRUE {
            addiu   t1, v0, 0x0024          // t1 = select entry's title
            sw      t1, 0x0000(t0)          // set the page title
        } else {
            sw      r0, 0x0000(t0)          // clear the page title
        }

        jal     Menu.redraw_                // redraw menu
        nop

        lli     a0, 13                      // a0 = group 13
        jal     Render.toggle_group_display_
        lli     a1, {hide_bg_image}         // toggle the main menu elements

        lw      t0, 0x0004(sp)              // restore t0
        lw      t1, 0x0008(sp)              // restore t1
        lw      ra, 0x000C(sp)              // restore ra
        addiu   sp, sp, 0x0010              // deallocate stack space
        jr      ra                          // return
        nop
    }

    info:
    Menu.info(head_super_menu, 30, 50, 3, 0, 32, 0xF2C70DFF, Color.high.WHITE, Color.high.WHITE)

    // @ Description
    // Functions to change the menu currently displayed.
    set_info_1_:; set_info_head(head_super_menu, OS.FALSE)
    set_info_2_:; set_info_head(head_remix_settings, OS.TRUE)
    set_info_3_:; set_info_head(head_music_settings, OS.TRUE)
    set_info_4_:; set_info_head(head_stage_settings, OS.TRUE)

    variable num_toggles(0)

    // @ Description
    // Wrapper for Menu.entry_bool()
    macro entry_bool(title, default_ce, default_te, default_jp, next) {
        global variable num_toggles(num_toggles + 1)
        evaluate n(num_toggles)
        global define TOGGLE_{n}_DEFAULT_CE({default_ce})
        global define TOGGLE_{n}_DEFAULT_TE({default_te})
        global define TOGGLE_{n}_DEFAULT_JP({default_jp})
        Menu.entry_bool({title}, {default_ce}, {next})
    }

    // @ Description
    // Wrapper for Menu.entry()
    macro entry(title, type, default_ce, default_te, default_jp, min, max, a_function, string_table, copy_address, next) {
        global variable num_toggles(num_toggles + 1)
        evaluate n(num_toggles)
        global define TOGGLE_{n}_DEFAULT_CE({default_ce})
        global define TOGGLE_{n}_DEFAULT_TE({default_te})
        global define TOGGLE_{n}_DEFAULT_JP({default_jp})
        Menu.entry({title}, {type}, {default_ce}, {min}, {max}, {a_function}, {string_table}, {copy_address}, {next})
    }

    // @ Description
    // Write defaults for the passed in profile
    // profile - CE or TE
    macro write_defaults_for(profile) {
        evaluate n(1)
        while {n} <= num_toggles {
            dw      {TOGGLE_{n}_DEFAULT_{profile}}
            evaluate n({n}+1)
        }
    }

    scope profile {
        constant CE(0)
        constant TE(1)
        constant JP(2)
        constant CUSTOM(3)
    }

    // @ Description
    // Profile strings
    profile_ce:; db "Community", 0x00
    profile_te:; db "Tournament", 0x00
    profile_jp:; db "Japanese", 0x00
    profile_custom:; db "Custom", 0x00
    current_profile:; db "Current Profile: ", 0x00
    toggles_note_line_1:; db "Press     to load selected profile,", 0x00
    toggles_note_line_2:; db "which will affect all settings.", 0x00
    settings:; db "SETTINGS", 0x00
    OS.align(4)

    string_table_profile:
    dw profile_ce
    dw profile_te
    dw profile_jp
    dw profile_custom

    // @ Description
    // FPS strings
    fps_off:; db "OFF", 0x00
    fps_normal:; db "NORMAL", 0x00
    fps_overclocked:; db "OVERCLOCKED", 0x00
    OS.align(4)

    string_table_fps:
    dw fps_off
    dw fps_normal
    dw fps_overclocked

    // @ Description
    // Special Model Display strings
    model_off:; db "OFF", 0x00
    model_hitbox:; db "HITBOX", 0x00
    model_skeleton:; db "SKELETON", 0x00
    model_ecb:; db "ECB", 0x00
    OS.align(4)

    string_table_model:
    dw model_off
    dw model_hitbox
    dw model_ecb
    dw model_skeleton

    // @ Description
    // Japanese Sounds strings
    jsounds_default:; db "DEFAULT", 0x00
    jsounds_always:; db "ALWAYS", 0x00
    jsounds_never:; db "NEVER", 0x00
    OS.align(4)

    string_table_jsounds:
    dw jsounds_default
    dw jsounds_always
    dw jsounds_never

    // @ Description
    // Menu Music strings
    menu_music_default:; db "DEFAULT", 0x00
    menu_music_64:; db "64", 0x00
    menu_music_melee:; db "MELEE", 0x00
    menu_music_brawl:; db "BRAWL", 0x00
    OS.align(4)

    string_table_menu_music:
    dw menu_music_default
    dw menu_music_64
    dw menu_music_melee
    dw menu_music_brawl

    // @ Description
    // SSS Layout strings
    sss_layout_normal:; db "NORMAL", 0x00
    sss_layout_tournament:; db "TOURNAMENT", 0x00
    OS.align(4)

    string_table_sss_layout:
    dw sss_layout_normal
    dw sss_layout_tournament

    scope sss {
        constant NORMAL(0)
        constant TOURNAMENT(1)
    }

    // @ Description
    // Hazard Mode strings
    hazard_mode_normal:; db "NORMAL", 0x00
    hazard_mode_hazards_off:; db "HAZARDS OFF", 0x00
    hazard_mode_movement_off:; db "MOVEMENT OFF", 0x00
    hazard_mode_all_off:; db "ALL OFF", 0x00
    OS.align(4)

    string_table_hazard_mode:
    dw hazard_mode_normal
    dw hazard_mode_hazards_off
    dw hazard_mode_movement_off
    dw hazard_mode_all_off

    scope hazard_mode {
        constant NORMAL(0)
        constant HAZARDS_OFF(1)
        constant MOVEMENT_OFF(2)
        constant ALL_OFF(3)
    }
    
    // @ Description
    // Allows A button to play selected menu music preference
    scope play_menu_music_: {
        addiu   sp, sp,-0x0014              // allocate stack space
        sw      a0, 0x0004(sp)              // ~
        sw      a1, 0x0008(sp)              // ~
        sw      t0, 0x000C(sp)              // ~
        sw      ra, 0x0010(sp)              // save registers

        li      t0, Toggles.entry_menu_music
        lw      t0, 0x0004(t0)              // t0 = 0 if DEFAULT, 1 if 64, 2 if MELEE, 3 if BRAWL

        lli     t1, 0x0001                  // t1 = 1 (64)
        beql    t1, t0, _play               // if 64, then use 64 BGM
        addiu   a1, r0, BGM.menu.MAIN
        lli     t1, 0x0002                  // t1 = 2 (MELEE)
        beql    t1, t0, _play               // if MELEE, then use MELEE BGM
        addiu   a1, r0, BGM.menu.MAIN_MELEE
        lli     t1, 0x0003                  // t1 = 3 (BRAWL)
        beql    t1, t0, _play               // if BRAWL, then use BRAWL BGM
        addiu   a1, r0, BGM.menu.MAIN_BRAWL

        b       _finish                     // if DEFAULT, then let's let the current track keep playing
        nop

        _play:
        lli     a0, 0x0000
        jal     BGM.play_
        nop

        _finish:
        lw      a0, 0x0004(sp)              // ~
        lw      a1, 0x0008(sp)              // ~
        lw      t0, 0x000C(sp)              // ~
        lw      ra, 0x0010(sp)              // restore registers
        addiu   sp, sp, 0x0014              // deallocate stack space
        jr      ra
        nop
    }

    // @ Description
    // Contains list of submenus.
    head_super_menu:
    Menu.entry("Load Profile:", Menu.type.U8, OS.FALSE, 0, 2, load_profile_, string_table_profile, OS.NULL, entry_remix_settings)
    entry_remix_settings:; Menu.entry_title("Remix Settings", set_info_2_, entry_music_settings)
    entry_music_settings:; Menu.entry_title("Music Settings", set_info_3_, entry_stage_settings)
    entry_stage_settings:; Menu.entry_title("Stage Settings", set_info_4_, OS.NULL)

    // @ Description 
    // Miscellaneous Toggles
    head_remix_settings:
    entry_practice_overlay:;            entry_bool("Color Overlays", OS.FALSE, OS.FALSE, OS.FALSE, entry_disable_cinematic_camera)
    entry_disable_cinematic_camera:;    entry_bool("Disable Cinematic Camera", OS.FALSE, OS.FALSE, OS.FALSE, entry_flash_on_z_cancel)
    entry_flash_on_z_cancel:;           entry_bool("Flash On Z-Cancel", OS.FALSE, OS.FALSE, OS.FALSE, entry_fps)
    entry_fps:;                         entry("FPS Display *BETA", Menu.type.U8, OS.FALSE, OS.FALSE, OS.FALSE, 0, 2, OS.NULL, string_table_fps, OS.NULL, entry_special_model)
    entry_special_model:;               entry("Special Model Display", Menu.type.U8, OS.FALSE, OS.FALSE, OS.FALSE, 0, 3, OS.NULL, string_table_model, OS.NULL, entry_hold_to_pause)
    entry_hold_to_pause:;               entry_bool("Hold To Pause", OS.FALSE, OS.TRUE, OS.FALSE, entry_improved_combo_meter)
    entry_improved_combo_meter:;        entry_bool("Improved Combo Meter", OS.TRUE, OS.FALSE, OS.TRUE, entry_tech_chase_combo_meter)
    entry_tech_chase_combo_meter:;      entry_bool("Tech Chase Combo Meter", OS.TRUE, OS.FALSE, OS.TRUE, entry_vs_mode_combo_meter)
    entry_vs_mode_combo_meter:;         entry_bool("VS Mode Combo Meter", OS.TRUE, OS.FALSE, OS.TRUE, entry_1v1_combo_meter_swap)
    entry_1v1_combo_meter_swap:;        entry_bool("1v1 Combo Meter Swap", OS.FALSE, OS.FALSE, OS.FALSE, entry_improved_ai)
    entry_improved_ai:;                 entry_bool("Improved AI", OS.TRUE, OS.FALSE, OS.TRUE, entry_neutral_spawns)
    entry_neutral_spawns:;              entry_bool("Neutral Spawns", OS.TRUE, OS.TRUE, OS.TRUE, entry_skip_results_screen)
    entry_skip_results_screen:;         entry_bool("Skip Results Screen", OS.FALSE, OS.FALSE, OS.FALSE, entry_salty_runback)
    entry_salty_runback:;               entry_bool("Salty Runback", OS.TRUE, OS.FALSE, OS.TRUE, entry_widescreen)
    entry_widescreen:;                  entry_bool("Widescreen", OS.FALSE, OS.FALSE, OS.FALSE, entry_japanese_hitlag)
    entry_japanese_hitlag:;             entry_bool("Japanese Hitlag", OS.FALSE, OS.FALSE, OS.TRUE, entry_japanese_di)
    entry_japanese_di:;                 entry_bool("Japanese DI", OS.FALSE, OS.FALSE, OS.TRUE, entry_japanese_sounds)
    entry_japanese_sounds:;             entry("Japanese Sounds", Menu.type.U8, 0, 0, 0, 0, 2, OS.NULL, string_table_jsounds, OS.NULL, entry_momentum_slide)
    entry_momentum_slide:;              entry_bool("Momentum Slide", OS.FALSE, OS.FALSE, OS.TRUE, entry_japanese_shieldstun)
    entry_japanese_shieldstun:;         entry_bool("Japanese Shield Stun", OS.FALSE, OS.FALSE, OS.TRUE, entry_variant_random)
	entry_variant_random:;              entry_bool("Random Select With Variants", OS.FALSE, OS.FALSE, OS.FALSE, entry_disable_pause_hud)
    entry_disable_pause_hud:;           entry_bool("Disable VS Pause HUD", OS.FALSE, OS.FALSE, OS.FALSE, entry_disable_aa)
    entry_disable_aa:;                  entry_bool("Disable Anti-Aliasing", OS.FALSE, OS.FALSE, OS.FALSE, OS.NULL)

    // @ Description
    // Random Music Toggles
    head_music_settings:
    entry_play_music:;                      entry_bool("Play Music", OS.TRUE, OS.TRUE, OS.TRUE, entry_menu_music)
    entry_menu_music:;                      entry("Menu Music", Menu.type.U8, 0, 0, 0, 0, 3, play_menu_music_, string_table_menu_music, OS.NULL, entry_random_music)
    entry_random_music:;                    entry_bool("Random Music", OS.FALSE, OS.FALSE, OS.FALSE, entry_random_music_bonus)
    entry_random_music_bonus:;              entry_bool("Bonus", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_congo_jungle)
    entry_random_music_congo_jungle:;       entry_bool("Congo Jungle", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_credits)
    entry_random_music_credits:;            entry_bool("Credits", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_data)
    entry_random_music_data:;               entry_bool("Data", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_dream_land)
    entry_random_music_dream_land:;         entry_bool("Dream Land", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_duel_zone)
    entry_random_music_duel_zone:;          entry_bool("Duel Zone", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_final_destination)
    entry_random_music_final_destination:;  entry_bool("Final Destination", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_how_to_play)
    entry_random_music_how_to_play:;        entry_bool("How To Play", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_hyrule_castle)
    entry_random_music_hyrule_castle:;      entry_bool("Hyrule Castle", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_meta_crystal)
    entry_random_music_meta_crystal:;       entry_bool("Meta Crystal", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_mushroom_kingdom)
    entry_random_music_mushroom_kingdom:;   entry_bool("Mushroom Kingdom", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_peachs_castle)
    entry_random_music_peachs_castle:;      entry_bool("Peach's Castle", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_planet_zebes)
    entry_random_music_planet_zebes:;       entry_bool("Planet Zebes", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_saffron_city)
    entry_random_music_saffron_city:;       entry_bool("Saffron City", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_sector_z)
    entry_random_music_sector_z:;           entry_bool("Sector Z", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_yoshis_island)
    entry_random_music_yoshis_island:;      entry_bool("Yoshi's Island", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_music_first_custom)

    entry_random_music_first_custom:
    // Add custom MIDIs
    define toggled_custom_MIDIs(0)
    define last_toggled_custom_MIDI(0)
    evaluate n(0x2F)
    while {n} < MIDI.midi_count {
        evaluate can_toggle({MIDI.MIDI_{n}_TOGGLE})
        if ({can_toggle} == OS.TRUE) {
            evaluate last_toggled_custom_MIDI({n})
            evaluate toggled_custom_MIDIs({toggled_custom_MIDIs}+1)
        }
        evaluate n({n}+1)
    }

    evaluate n(0x2F)
    while {n} < MIDI.midi_count {
        entry_random_music_{n}:                                        // always create the label even if we don't create the entry
        evaluate can_toggle({MIDI.MIDI_{n}_TOGGLE})
        if ({can_toggle} == OS.TRUE) {
            if ({n} == {last_toggled_custom_MIDI}) {
                evaluate next(OS.NULL)
            } else {
                evaluate m({n}+1)
                evaluate next(entry_random_music_{m})
            }
            entry_bool("{MIDI.MIDI_{n}_NAME}", OS.TRUE, OS.TRUE, OS.TRUE, {next})
        }
        evaluate n({n}+1)
    }

    // @ Description
    // Stage Toggles
    head_stage_settings:
    entry_sss_layout:;                          entry("Stage Select Layout", Menu.type.U8, sss.NORMAL, sss.TOURNAMENT, sss.NORMAL, 0, 1, OS.NULL, string_table_sss_layout, OS.NULL, entry_hazard_mode)
    entry_hazard_mode:;                         entry("Hazard Mode", Menu.type.U8, hazard_mode.NORMAL, hazard_mode.NORMAL, hazard_mode.NORMAL, 0, 3, OS.NULL, string_table_hazard_mode, OS.NULL, entry_random_stage_title)
    entry_random_stage_title:;                  Menu.entry_title("Random Stage Toggles:", OS.NULL, entry_random_stage_congo_jungle)
    entry_random_stage_congo_jungle:;           entry_bool("Congo Jungle", OS.TRUE, OS.FALSE, OS.TRUE, entry_random_stage_dream_land)
    entry_random_stage_dream_land:;             entry_bool("Dream Land", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_stage_dream_land_beta_1)
    entry_random_stage_dream_land_beta_1:;      entry_bool("Dream Land Beta 1", OS.FALSE, OS.FALSE, OS.FALSE, entry_random_stage_dream_land_beta_2)
    entry_random_stage_dream_land_beta_2:;      entry_bool("Dream Land Beta 2", OS.FALSE, OS.FALSE, OS.FALSE, entry_random_stage_duel_zone)
    entry_random_stage_duel_zone:;              entry_bool("Duel Zone", OS.TRUE, OS.FALSE, OS.TRUE, entry_random_stage_final_destination)
    entry_random_stage_final_destination:;      entry_bool("Final Destination", OS.TRUE, OS.FALSE, OS.TRUE, entry_random_stage_how_to_play)
    entry_random_stage_how_to_play:;            entry_bool("How to Play", OS.FALSE, OS.FALSE, OS.FALSE, entry_random_stage_hyrule_castle)
    entry_random_stage_hyrule_castle:;          entry_bool("Hyrule Castle", OS.TRUE, OS.FALSE, OS.TRUE, entry_random_stage_meta_crystal)
    entry_random_stage_meta_crystal:;           entry_bool("Meta Crystal", OS.TRUE, OS.FALSE, OS.TRUE, entry_random_stage_mushroom_kingdom)
    entry_random_stage_mushroom_kingdom:;       entry_bool("Mushroom Kingdom", OS.TRUE, OS.FALSE, OS.TRUE, entry_random_stage_peachs_castle)
    entry_random_stage_peachs_castle:;          entry_bool("Peach's Castle", OS.TRUE, OS.FALSE, OS.TRUE, entry_random_stage_planet_zebes)
    entry_random_stage_planet_zebes:;           entry_bool("Planet Zebes", OS.TRUE, OS.FALSE, OS.TRUE, entry_random_stage_saffron_city)
    entry_random_stage_saffron_city:;           entry_bool("Saffron City", OS.TRUE, OS.FALSE, OS.TRUE, entry_random_stage_sector_z)
    entry_random_stage_sector_z:;               entry_bool("Sector Z", OS.TRUE, OS.FALSE, OS.TRUE, entry_random_stage_yoshis_island)
    entry_random_stage_yoshis_island:;          entry_bool("Yoshi's Island", OS.TRUE, OS.FALSE, OS.TRUE, entry_random_stage_mini_yoshis_island)
    entry_random_stage_mini_yoshis_island:;     entry_bool("Mini Yoshi's Island", OS.TRUE, OS.TRUE, OS.TRUE, entry_random_stage_first_custom)

    entry_random_stage_first_custom:
    // Add custom stages
    define toggled_custom_stages(0)
    define last_toggled_custom_stage(0)
    evaluate n(0x29)
    while {n} <= Stages.id.MAX_STAGE_ID {
        evaluate can_toggle({Stages.STAGE_{n}_TOGGLE})
        if ({can_toggle} == OS.TRUE) {
            evaluate last_toggled_custom_stage({n})
            evaluate toggled_custom_stages({toggled_custom_stages}+1)
        }
        evaluate n({n}+1)
    }

    map 0x7E, 0x7F, 1 // temporarily make ~ be Omega
    evaluate n(0x29)
    while {n} <= Stages.id.MAX_STAGE_ID {
        entry_random_stage_{n}:                                        // always create the label even if we don't create the entry
        evaluate can_toggle({Stages.STAGE_{n}_TOGGLE})
        if ({can_toggle} == OS.TRUE) {
            if ({n} == {last_toggled_custom_stage}) {
                evaluate next(OS.NULL)
            } else {
                evaluate m({n}+1)
                evaluate next(entry_random_stage_{m})
            }
            entry_bool({Stages.STAGE_{n}_TITLE}, OS.TRUE, {Stages.STAGE_{n}_LEGAL}, OS.TRUE, {next})
        }
        evaluate n({n}+1)
    }
    map 0, 0, 256 // restore string mappings

    // @ Description
    // SRAM blocks for toggle saving.
    block_misc:; SRAM.block(23 * 4)
    block_music:; SRAM.block((19 + {toggled_custom_MIDIs}) * 4)
    block_stages:; SRAM.block((18 + {toggled_custom_stages}) * 4)

    profile_defaults_CE:; write_defaults_for(CE)
    profile_defaults_TE:; write_defaults_for(TE)
    profile_defaults_JP:; write_defaults_for(JP)

    // @ Description
    // This function will load toggle settings based on the selected profile
    scope load_profile_: {
        addiu   sp, sp,-0x001C                 // allocate stack space
        sw      ra, 0x0004(sp)                 // ~
        sw      t0, 0x0008(sp)                 // ~
        sw      t1, 0x000C(sp)                 // ~
        sw      t2, 0x0010(sp)                 // ~
        sw      t3, 0x0014(sp)                 // ~
        sw      t4, 0x0018(sp)                 // save registers

        li      t0, head_super_menu            // t0 = address of menu entry
        lw      t0, 0x0004(t0)                 // t0 = selected profile
        lli     t1, profile.CE                 // t1 = profile.CE
        li      t2, profile_defaults_CE        // t2 = address of CE defaults
        beq     t0, t1, _load                  // if (selected profile is CE), skip to _load
        nop                                    // otherwise apply CE defaults:
        lli     t1, profile.TE                 // t1 = profile.TE
        li      t2, profile_defaults_TE        // t2 = address of TE defaults
        beq     t0, t1, _load                  // if (selected profile is TE), skip to _load
        nop                                    // otherwise apply TE defaults:
        li      t2, profile_defaults_JP        // t2 = address of JP defaults

        _load:
        li      t0, head_remix_settings        // t0 = first remix setting entry address

        _begin:
        addu    t3, r0, t0                     // t3 = head

        _loop:
        beqz    t0, _next                      // if (entry = null), go to next
        nop

        // skip titles
        lli     t4, Menu.type.TITLE            // t4 = title type
        lw      t1, 0x0000(t0)                 // t1 = type
        beq     t4, t1, _skip                  // if (type == title), skip
        nop

        lw      t1, 0x0000(t2)                 // t1 = default profile value
        sw      t1, 0x0004(t0)                 // store default value as current value
        addiu   t2, t2, 0x0004                 // increment ram_address

        _skip:
        lw      t0, 0x001C(t0)                 // t0 = entry->next
        b       _loop                          // check again
        nop

        _next:
        li      t1, head_remix_settings        // t1 = first remix setting entry address
        li      t0, head_music_settings        // t0 = first music setting entry address
        beq     t3, t1, _begin                 // if (finished the remix block) then do the music block next
        nop                                    // ~
        or      t1, r0, t0                     // t1 = first music setting entry address
        li      t0, head_stage_settings        // t0 = first stage setting entry address
        beq     t3, t1, _begin                 // if (finished the music block) then do the random stage block next
        nop                                    // ~

        _end:
        lw      ra, 0x0004(sp)                 // ~
        lw      t0, 0x0008(sp)                 // ~
        lw      t1, 0x000C(sp)                 // ~
        lw      t2, 0x0010(sp)                 // ~
        lw      t3, 0x0014(sp)                 // ~
        lw      t4, 0x0018(sp)                 // restore registers
        addiu   sp, sp, 0x001C                 // deallocate stack sapce
        jr      ra                             // return
        nop
    }

    // @ Description
    // This function will figure out the current profile based on the current toggle values
    // @ Returns
    // v0 - current profile_id
    scope get_current_profile_: {
        addiu   sp, sp,-0x0020                 // allocate stack space
        sw      ra, 0x0004(sp)                 // ~
        sw      t0, 0x0008(sp)                 // ~
        sw      t1, 0x000C(sp)                 // ~
        sw      t2, 0x0010(sp)                 // ~
        sw      t3, 0x0014(sp)                 // ~
        sw      t4, 0x0018(sp)                 // ~
        sw      t5, 0x001C(sp)                 // save registers

        lli     v0, profile.CE                 // v0 = CE

        li      t2, profile_defaults_CE        // t2 = address of CE defaults

        _load:
        addu    t5, r0, t2                     // t5 = defaults table
        li      t0, head_remix_settings        // t0 = first remix setting entry address

        _begin:
        addu    t4, r0, t0                     // t4 = head

        _loop:
        beqz    t0, _next                      // if (entry = null), go to next
        nop

        // skip titles when importing
        lli     t3, Menu.type.TITLE            // t3 = title type
        lw      t1, 0x0000(t0)                 // t1 = type
        beq     t3, t1, _skip                  // if (type == title), skip
        nop

        lw      t1, 0x0000(t2)                 // t1 = default profile value
        lw      t3, 0x0004(t0)                 // t3 = current value
        bne     t1, t3, _next_profile          // if (default value != current value) then this profile isn't loaded
        nop
        addiu   t2, t2, 0x0004                 // increment ram_address

        _skip:
        lw      t0, 0x001C(t0)                 // t0 = entry->next
        b       _loop                          // check again
        nop

        _next:
        or      t3, r0, t0                     // save t0
        li      t1, head_remix_settings        // t1 = first remix setting entry address
        li      t0, head_music_settings        // t0 = first music setting entry address
        beq     t4, t1, _begin                 // if (finished the remix block) then do the music block next
        nop                                    // ~
        or      t1, r0, t0                     // t1 = first music setting entry address
        li      t0, head_stage_settings        // t0 = first stage setting entry address
        beq     t4, t1, _begin                 // if (finished the music block) then do the random stage block next
        nop                                    // ~
        or      t0, r0, t3                     // restore t0

        _next_profile:
        beqz    t0, _end                       // if (entry = null), then we have the correct profile in v0
        nop
        lli     v0, profile.TE                 // v0 = TE
        li      t1, profile_defaults_CE        // t1 = address of CE defaults
        li      t3, profile_defaults_TE        // t3 = address of TE defaults
        beql    t5, t1, _load                  // if (just confirmed not CE) then check if TE next
        or      t2, r0, t3                     // ~

        lli     v0, profile.JP                 // v0 = JP
        li      t1, profile_defaults_TE        // t1 = address of TE defaults
        li      t3, profile_defaults_JP        // t3 = address of JP defaults
        beql    t5, t1, _load                  // if (just confirmed not TE) then check if JP next
        or      t2, r0, t3                     // ~

        // if we made it here, it's not CE or TE
        lli     v0, profile.CUSTOM             // v0 = CUSTOM

        _end:
        lw      ra, 0x0004(sp)                 // ~
        lw      t0, 0x0008(sp)                 // ~
        lw      t1, 0x000C(sp)                 // ~
        lw      t2, 0x0010(sp)                 // ~
        lw      t3, 0x0014(sp)                 // ~
        lw      t4, 0x0018(sp)                 // ~
        lw      t5, 0x001C(sp)                 // restore registers
        addiu   sp, sp, 0x0020                 // deallocate stack sapce
        jr      ra                             // return
        nop
    }
}


} // __TOGGLES__
