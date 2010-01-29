"use strict";

var OTRS = OTRS || {};
OTRS.Fred = OTRS.Fred || {};

/**
 * @namespace
 * @description
 *      This namespace contains all logic for the Fred module JSLint
 */
OTRS.Fred.JSLint = (function () {
    /**
     * @function
     * @private
     * @return nothing
     * @description Start JSLint check.
     */
    function StartJSLint() {
        var Result;

        // This func should not be started more than one time...
        OTRS.Fred.JSLint.Started++;

        // Start JSLint vor every script we found and output the result
        $.each(OTRS.Fred.JSLint.AllScripts, function() {
            var ErrorObject, Output, i;

            Result = JSLINT(this.Script, OTRS.Fred.JSLint.Options);
            if (!Result) {
                for (i = 0; i < JSLINT.errors.length; i++) {
                    ErrorObject = JSLINT.errors[i];
                    if (ErrorObject) {
                        Output = '<div class="FredJSLintError"><p>';
                        Output += '<strong>Source: ' + this.Src + ', Line ' + ErrorObject.line;
                        Output += ', character ' + ErrorObject.character + ':</strong></p>';
                        Output += '<pre>' + ErrorObject.evidence + '</pre><p>' + ErrorObject.reason;
                        Output += '</p></div>';
                        $('#FredJSLintScripts').append(Output);
                    }
                }
            }
            else {
                $('#FredJSLintScripts').append('<p class="FredJSLintSuccessfull">' + this.Src + ': No errors found!</p>');
            }
        });

        if (OTRS.Fred.JSLint.AllScripts.length === 0) {
            $('#FredJSLintScripts').append('<p>No scripts found!</p>').css('height', '15px');
        }
    }

    return {
        /**
         * @field
         * @description All options for JSLint.
         */
        Options: {
            browser: true,
            white: true,
            devel: true,
            onevar: true,
            undef: true,
            nomen: true,
            eqeqeq: true,
            plusplus: false,
            bitwise: true,
            regexp: true,
            strict: true,
            immed: true,
            predef: ['OTRS', '$'],
        },

        AllScripts: [],
        Waiting: 0,
        Started: 0,
        Sources: {},
        OldOnLoadFunc: {},

        /**
         * @function
         * @return nothing.
         * @description
         *      This is the init function for JSLint.
         */
        Init: function () {
            OTRS.Fred.JSLint.OldOnLoadFunc = window.onload;
            window.onload = function() {
                // this module needs jQuery!
                if (typeof jQuery == 'undefined' || !jQuery) {
                    alert('Fred JSLint module needs jQuery loaded');
                    document.getElementById('FredJSLintScripts').style.height = '15px';
                }
                else {
                    OTRS.Fred.JSLint.GetScripts();
                }
                if (typeof OTRS.Fred.JSLint.OldOnLoadFunc != "undefined")
                    OTRS.Fred.JSLint.OldOnLoadFunc();
            }
        },

        /**
         * @function
         * @return nothing
         * @description Get all scripts to check.
         */
        GetScripts: function () {
            $(document).ready(function() {
                var Scripts, Source;

                $('script').each(function() {
                    // Exclude the Fred JavaScript ;-)
                    if (!($(this).is('[rel=fred]'))) {
                        Scripts = $(this).text();
                        if ($(this).is('[src]'))
                            Source = $(this).attr('src');
                        else
                            Source = 'inline';

                        if (Source == 'inline')
                        {
                            OTRS.Fred.JSLint.AllScripts.push({Src: Source, Script: Scripts});
                        }
                        else
                        {
                            // If external source is not a thirdparty script, load it!
                            if (!Source.match(/thirdparty/) && !Source.match(/chrome:\/\//) && !OTRS.Fred.JSLint.Sources[Source]) {
                                OTRS.Fred.JSLint.Waiting++;
                                OTRS.Fred.JSLint.Sources[Source] = 1;
                                $.get(Source, {}, function(data) {
                                    OTRS.Fred.JSLint.AllScripts.push({Src: this.url, Script: data});
                                    OTRS.Fred.JSLint.Waiting--;
                                    setTimeout("OTRS.Fred.JSLint.CheckForStart()", 250);
                                });
                            }
                        }
                     }
                });

                // start jslint, if all ajax requests are ready
                setTimeout("OTRS.Fred.JSLint.CheckForStart()", 250);
            });
        },

        /**
         * @function
         * @return nothing.
         * @description
         *      This function checks, if JSLint can be started (all scripts are loaded).
         */
        CheckForStart: function () {
            if (OTRS.Fred.JSLint.Waiting <= 0 && OTRS.Fred.JSLint.Started === 0) {
                StartJSLint();
            }
            else {
                if (OTRS.Fred.JSLint.Started === 0) {
                    setTimeout("OTRS.Fred.JSLint.CheckForStart()", 250);
                }
            }
        }
    };
}());