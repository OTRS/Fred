// --
// Core.Fred.js - Generic Fred functions
// Copyright (C) 2001-2013 OTRS AG, http://otrs.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var Core = Core || {};
Core.Fred = Core.Fred || {};

/**
 * @namespace
 * @description
 *      This namespace contains all logic for Fred
 */
Core.Fred = (function (TargetNS) {

    /**
     * @function
     * @return nothing.
     * @description
     *      This function inits generic fred functions
     */
    TargetNS.Init = function () {

        $('.FredSearch').bind('click', function() {
            $(this).closest('.DevelFredBox').find('.FredQuickSearch').toggle();
        });

        $('.FredMinimize').bind('click', function() {
            $(this).closest('.DevelFredBox').find('.DevelFredBoxContent').slideToggle('fast');
        });

        $('.FredClose').bind('click', function() {
            $(this).closest('.DevelFredBox').remove();
        });

        $('.FredQuickSearch i').bind('click', function() {
            $(this).prev('input').val('').trigger('keydown');
        });

        $('.FredQuickSearch input').each(function() {
            Core.UI.Table.InitTableFilter($(this), $(this).closest('.DevelFredBox').find('.FredTableDefault'));
        });

        // register new popup profile as needed by fred
        Core.UI.Popup.ProfileAdd('FredSettings', {
            WindowURLParams: "dependent=yes,location=no,menubar=no,resizable=yes,scrollbars=yes,status=no,toolbar=no",
            Left:            100,
            Top:             100,
            Width:           230,
            Height:          350
        });
        $('.FredSettings').bind('click', function() {
            Core.UI.Popup.OpenPopup($(this).data('url'), 'FredSettings', 'FredSettings');
        });
    };

    TargetNS.Init();

    return TargetNS;
}(Core.Fred.JSLint || {}));
