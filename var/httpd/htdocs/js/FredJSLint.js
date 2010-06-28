"use strict";
/*global JSLINT: false */

var Core = Core || {};
Core.Fred = Core.Fred || {};

/**
 * @namespace
 * @description
 *      This namespace contains all logic for the Fred module JSLint
 */
Core.Fred.JSLint = (function (TargetNS) {
    /**
     * @function
     * @private
     * @return nothing
     * @description Start JSLint check.
     */
    function StartJSLint() {
        var Result;

        // This func should not be started more than one time...
        TargetNS.Started++;

        // Start JSLint for every script we found and output the result
        $.each(TargetNS.AllScripts, function () {
            var ErrorObject, Output, i;

            Result = JSLINT(this.Script, TargetNS.Options);
            if (!Result) {
                for (i = 0; i < JSLINT.errors.length; i++) {
                    ErrorObject = JSLINT.errors[i];
                    if (ErrorObject) {
                        Output = '<div class="FredJSLintError">';
                        Output += '<p><span class="Error">Error: </span><strong>' + ErrorObject.reason + '</strong> Source:     ' + this.Src + ':' + ErrorObject.line + ':' + ErrorObject.character + '</p>';
                        Output += '<code>' + ErrorObject.evidence + '</code>';
                        Output += '</div>';
                        $('#FredJSLintScripts').append(Output);
                    }
                }
            }
            else {
                $('#FredJSLintScripts').append('<p class="FredJSLintSuccessfull">' + this.Src + ' ok</p>');
            }
        });

        if (TargetNS.AllScripts.length === 0) {
            $('#FredJSLintScripts').append('<p>No scripts found!</p>').css('height', '15px');
        }
    }

    /**
     * @field
     * @description All options for JSLint.
     */
    TargetNS.Options = {
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
            predef: ['Core', 'isJQueryObject', '$', 'jQuery', 'CKEDITOR', 'window', 'document']
        };

    TargetNS.AllScripts = TargetNS.AllScripts || [];
    TargetNS.Waiting = 0;
    TargetNS.Started = 0;
    TargetNS.Sources = {};

    /**
     * @function
     * @return nothing.
     * @description
     *      This is the init function for JSLint.
     */
    TargetNS.Init = function () {
        // this module needs jQuery!
        if (typeof jQuery === 'undefined' || !jQuery) {
            alert('Fred JSLint module needs jQuery loaded');
            document.getElementById('FredJSLintScripts').style.height = '15px';
        }
        else {
            $(document).ready(function () {
                Core.Fred.JSLint.GetScripts();
            });
        }
    };

    /**
     * @function
     * @return nothing
     * @description Get all scripts to check.
     */
    TargetNS.GetScripts = function () {
        $(document).ready(function () {
            var Scripts, Source;

            $('script').each(function () {
                // Exclude the Fred JavaScript ;-)
                Scripts = $(this).text();

                if ($(this).is('[src]')) {
                    Source = $(this).attr('src');
                }
                else {
                    Source = 'inline';
                }

                if (Source === 'inline') {
                    TargetNS.AllScripts.push({Src: Source, Script: Scripts});
                }
                else {
                    // If external source is not a thirdparty script, load it!
                    if (!Source.match(/thirdparty/) && !Source.match(/chrome:\/\//) && !TargetNS.Sources[Source]) {
                        TargetNS.Waiting++;
                        TargetNS.Sources[Source] = 1;
                        $.get(Source, {}, function (data) {
                            TargetNS.AllScripts.push({Src: this.url, Script: data});
                            TargetNS.Waiting--;
                            setTimeout(function () {
                                Core.Fred.JSLint.CheckForStart();
                            }, 250);
                        });
                    }
                }
            });

            // start jslint, if all ajax requests are ready
            setTimeout(function () {
                Core.Fred.JSLint.CheckForStart();
            }, 250);
        });
    };

    /**
     * @function
     * @return nothing.
     * @description
     *      This function checks, if JSLint can be started (all scripts are loaded).
     */
    TargetNS.CheckForStart = function () {
        if (TargetNS.Waiting <= 0 && TargetNS.Started === 0) {
            StartJSLint();
        }
        else {
            if (TargetNS.Started === 0) {
                setTimeout(function () {
                    Core.Fred.JSLint.CheckForStart();
                }, 250);
            }
        }
    };
    return TargetNS;
}(Core.Fred.JSLint || {}));