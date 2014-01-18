// Copyright 2012-2013 OpenStack Foundation
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License. You may obtain
// a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

window.zuul_enable_status_updates = true;
window.zuul_filter = [];
window.zuul_collapsed_exceptions = [];

function format_enqueue_time(time) {
    var hours = 60 * 60 * 1000;
    var now = Date.now();
    var delta = now - time;
    var status = "queue_good";
    var text = format_time(delta, true);
    if (delta > (4 * hours)) {
        status = "queue_bad";
    } else if (delta > (2 * hours)) {
        status = "queue_warn";
    }
    return '<span class="' + status + '">' + text + '</span>';
}

function format_time(ms, words) {
    if (ms == null) {
        return "unknown";
    }
    var seconds = (+ms)/1000;
    var minutes = Math.floor(seconds/60);
    var hours = Math.floor(minutes/60);
    seconds = Math.floor(seconds % 60);
    minutes = Math.floor(minutes % 60);
    r = '';
    if (words) {
        if (hours) {
            r += hours;
            r += ' hr ';
        }
        r += minutes + ' min';
    } else {
        if (hours < 10) r += '0';
        r += hours + ':';
        if (minutes < 10) r += '0';
        r += minutes + ':';
        if (seconds < 10) r += '0';
        r += seconds;
    }
    return r;
}

function format_progress(elapsed, remaining) {
    if (remaining != null) {
        total = elapsed + remaining;
    } else {
        total = null;
    }
    r = '<progress class="change_progress" title="' +
        format_time(elapsed, false) + ' elapsed, ' +
        format_time(remaining, false)+' remaining" ' +
        'value="'+elapsed+'" max="'+total+'">in progress</progress>';
    return r;
}

function is_hide_project(project) {
    var filters = window.zuul_filter;
    if (filters.length == 0) {
        return false;
    }
    var hide = true;
    $.each(filters, function(filter_i, filter) {
        if(project.indexOf(filter) != -1)
            hide = false;
    });
    return hide;
}

function remove(l, idx) {
    l[idx] = null;
    while (l[l.length-1] === null) {
        l.pop();
    }
}

function create_tree(pipeline) {
    var count = 0;
    var pipeline_max_tree_columns = 1;
    $.each(pipeline['change_queues'], function(change_queue_i, change_queue) {
        var tree = [];
        var max_tree_columns = 1;
        var changes = [];
        var last_tree_length = 0;
        $.each(change_queue['heads'], function(head_i, head) {
            $.each(head, function(change_i, change) {
                changes[change['id']] = change;
                change['_tree_position'] = change_i;
            });
        });
        $.each(change_queue['heads'], function(head_i, head) {
            $.each(head, function(change_i, change) {
                count += 1;
                var idx = tree.indexOf(change['id']);
                if (idx > -1) {
                    change['_tree_index'] = idx;
                    remove(tree, idx);
                } else {
                    change['_tree_index'] = 0;
                }
                change['_tree_branches'] = [];
                change['_tree'] = [];
                change['items_behind'].sort(function(a, b) {
                    return changes[b]['_tree_position'] - changes[a]['_tree_position'];
                });
                $.each(change['items_behind'], function(i, id) {
                    tree.push(id);
                    if (tree.length>last_tree_length && last_tree_length > 0)
                        change['_tree_branches'].push(tree.length-1);
                });
                if (tree.length > max_tree_columns) {
                    max_tree_columns = tree.length;
                }
                if (tree.length > pipeline_max_tree_columns) {
                    pipeline_max_tree_columns = tree.length;
                }
                change['_tree'] = tree.slice(0);  // make a copy
                last_tree_length = tree.length;
            });
        });
        change_queue['_tree_columns'] = max_tree_columns;
    });
    pipeline['_tree_columns'] = pipeline_max_tree_columns;
    return count;
}

function get_sparkline_url(pipeline_name) {
    if (!(pipeline_name in window.zuul_sparkline_urls)) {
        window.zuul_sparkline_urls[pipeline_name] = $.fn.graphite.geturl({
            url: "http://graphite.openstack.org/render/",
            from: "-8hours",
            width: 100,
            height: 16,
            margin: 0,
            hideLegend: true,
            hideAxes: true,
            hideGrid: true,
            target: [
                "color(stats.gauges.zuul.pipeline."+pipeline_name+".current_changes, '6b8182')"
            ]
        });
    }
    return window.zuul_sparkline_urls[pipeline_name];
}

function format_pipeline(data) {
    var count = create_tree(data);
    var width = (16 * data['_tree_columns']) + 300;
    var html = '<div class="pipeline" style="width:'+width+'"><h3 class="subhead">'+
        data['name'];

    html += '<span class="count"><img src="' + get_sparkline_url(data['name']);
    html += '" title="8 hour history of changes in pipeline"/>';

    if (count > 0) {
        html += ' (' + count + ')';
    }
    html += '</span></h3>';
    if (data['description'] != null) {
        html += '<p>'+data['description']+'</p>';
    }

    $.each(data['change_queues'], function(change_queue_i, change_queue) {
        $.each(change_queue['heads'], function(head_i, head) {
            var projects = "";
            var hide_queue = true;
            $.each(head, function(change_i, change) {
                projects += change['project'] + "|";
                hide_queue &= is_hide_project(change['project']);
            });
            html += '<div project="' + projects + '" style="'
                + (hide_queue ? 'display:none;' : '') + '">';

            if (data['change_queues'].length > 1 && head_i == 0) {
                html += '<div> Change queue: ';

                var name = change_queue['name'];
                html += '<a title="' + name + '">';
                if (name.length > 32) {
                    name = name.substr(0,32) + '...';
                }
                html += name + '</a></div>';
            }
            html += '<table>';
            $.each(head, function(change_i, change) {
                html += format_change(change, change_queue);
            });
            html += '</table></div>';
        });
    });

    html += '</div>';
    return html;
}

function safe_id(id) {
    if (id === null) {
        return "null";
    }
    return id.replace(',', '_');
}

function format_change(change, change_queue) {
    var html = '<tr>';

    for (var i=0; i<change_queue['_tree_columns']; i++) {
        var cls = 'tree';
        if (i < change['_tree'].length && change['_tree'][i] !== null) {
            cls += ' line';
        }
        html += '<td class="'+cls+'">';
        if (i == change['_tree_index']) {
            if (change['failing_reasons'] && change['failing_reasons'].length > 0) {
                var reason = change['failing_reasons'].join(', ');
                var image = 'red.png';
                if (reason.match(/merge conflict/)) {
                    image = 'black.png';
                }
                html += '<img src="' + image + '" title="Failing because ' + reason +'"/>';
            } else {
                html += '<img src="green.png" title="Succeeding"/>';
            }
        }
        if (change['_tree_branches'].indexOf(i) != -1) {
            if (change['_tree_branches'].indexOf(i) == change['_tree_branches'].length-1)
                html += '<img src="line-angle.png"/>';
            else
                html += '<img src="line-t.png"/>';
        }
        html += '</td>';
    }

    html += '<td class="change-container">';
    html += '<div class="change" id="' + safe_id(change['id']) + '">' +
            '<div class="header" onClick="toggle_display_jobs(event, this)" ' +
            'onmouseover="$(this).addClass(\'hover\')" ' +
            'onmouseout="$(this).removeClass(\'hover\')">';

    html += '<span class="project">' + change['project'] + '</span>';

    display = $('#expandByDefault').is(':checked');
    safe_change_id = safe_id(change['id']);
    collapsed_index = window.zuul_collapsed_exceptions.indexOf(safe_change_id);
    if (collapsed_index > -1) {
        /* listed as an exception to the current default */
        display = !display;
    }

    html += '<span class="time">';
    html += format_time(change['remaining_time'], true);
    html += '</span><br/>';

    // Row #2 of the header (change id and enqueue time)
    html += '<span class="changeid"> ';
    var id = change['id'];
    var url = change['url'];
    if (id !== null) {
        if (id.length == 40) {
            id = id.substr(0,7);
        }
        if (url !== null) {
            html += '<a href="'+url+'">';
        }
        html += id;
        if (url !== null) {
            html += '</a>';
        }
    } else {
        // if there is not changeset we still need forced content, otherwise
        // the layout doesn't work
        html += '&nbsp;';
    }
    html += '</span>';
    html += '<span class="time">' + format_enqueue_time(change['enqueue_time']) + '</span>';

    html += '</div>';

    // Job listing from here down
    html += '<div class="jobs"';
    if (display == false) {
        html += ' style="display: none;"';
    }
    html += '>';

    $.each(change['jobs'], function(i, job) {
        result = job['result'];
        var result_class = "result";
        if (result === null) {
            if (job['url'] !== null) {
                result = 'in progress';
            } else {
                result = 'queued';
            }
        } else if (result == 'SUCCESS') {
            result_class += " result_success";
        } else if (result == 'FAILURE') {
            result_class += " result_failure";
        } else if (result == 'LOST') {
            result_class += " result_unstable";
        } else if (result == 'UNSTABLE') {
            result_class += " result_unstable";
        }
        html += '<span class="jobwrapper"><span class="job">';
        if (job['url'] !== null) {
            html += '<a href="'+job['url']+'">';
        }
        html += job['name'];
        if (job['url'] !== null) {
            html += '</a>';
        }
        html += ': ';
        if (job['result'] === null && job['url'] !== null) {
            html += format_progress(job['elapsed_time'], job['remaining_time']);
        } else {
            html += '<span class="result '+result_class+'">'+result+'</span>';
        }

        if (job['voting'] == false) {
            html += ' (non-voting)';
        }
        html += '</span></span>';
    });

    html += '</div></div></td></tr>';
    return html;
}

function toggle_display_jobs(e, _header) {
    e = e || window.event;  // standards compliant || IE
    var header = $(_header);
    var target = $(e.target || e.srcElement);
    var link = header.find("a");
    if (target.is(link)) {
        return true;
    }

    content = header.next("div");
    content.slideToggle(100, function () {
        changeid = header.parent().attr('id');
        collapsed_index = window.zuul_collapsed_exceptions.indexOf(changeid);
        expand_by_default = $('#expandByDefault').is(':checked');
        visible = content.is(":visible");
        if (expand_by_default != visible && collapsed_index == -1) {
            /* now an exception to the default */
            window.zuul_collapsed_exceptions.push(changeid);
        } else if (collapsed_index > -1) {
            window.zuul_collapsed_exceptions.splice(collapsed_index, 1);
        }
    });
}

function toggle_expand_by_default(_checkbox) {
    var checkbox = $(_checkbox);
    expand_by_default = checkbox.is(':checked');
    set_cookie('zuul-expand-by-default', expand_by_default ? 'true' : 'false');
    window.zuul_collapsed_exceptions = [];
    $.each($('div.change'), function(i, _change) {
        change = $(_change);
        content = change.children('div').next('div');
        if (expand_by_default) {
            content.show(0);
        } else {
            content.hide(0);
        }
    });
}

function update_timeout() {
    if (!window.zuul_enable_status_updates) {
        setTimeout(update_timeout, 5000);
        return;
    }

    window.zuul_graph_update_count += 1;

    update();
    /* Only update graphs every minute */
    if (window.zuul_graph_update_count > 11) {
        window.zuul_graph_update_count = 0;
        update_graphs();
    }

    setTimeout(update_timeout, 5000);
}

function clean_changes_lists() {
    new_collapsed_exceptions = [];

    $.each($('div.change'), function(i, change) {
        collapsed_index = window.zuul_collapsed_exceptions.indexOf(change.id);
        if (collapsed_index > -1) {
            new_collapsed_exceptions.push(change.id);
            return;
        }
    });

    window.zuul_collapsed_exceptions = new_collapsed_exceptions;
}

function update() {
    var html = '';

    $.getJSON('http://zuul.openstack.org/status.json', function(data) {
        if ('message' in data) {
            $("#message").attr('class', 'alertbox');
            $("#message").html(data['message']);
        } else {
            $("#message").removeClass('alertbox');
            $("#message").html('');
        }

        html += '<br style="clear:both"/>';

        $.each(data['pipelines'], function(i, pipeline) {
            html = html + format_pipeline(pipeline);
        });

        html += '<br style="clear:both"/>';
        $("#pipeline-container").html(html);

        $("#trigger_event_queue_length").html(
            data['trigger_event_queue']['length']);
        $("#result_event_queue_length").html(
            data['result_event_queue']['length']);

    });

    clean_changes_lists();
}

function update_graphs() {
    $('.graph').each(function(i, img) {
        var newimg = new Image();
        var parts = img.src.split('#');
        newimg.src = parts[0] + '#' + new Date().getTime();
        $(newimg).load(function (x) {
            img.src = newimg.src;
        });
    });

    $.each(window.zuul_sparkline_urls, function(name, url) {
        var newimg = new Image();
        var parts = url.split('#');
        newimg.src = parts[0] + '#' + new Date().getTime();
        $(newimg).load(function (x) {
            window.zuul_sparkline_urls[name] = newimg.src;
        });
    });
}

function save_filter() {
    var name = 'zuul-project-filter';
    var value = $('#projects_filter').val().trim();
    set_cookie(name, value);
    $('img.filter-saved').removeClass('hidden');
    window.setTimeout(function(){
        $('img.filter-saved').addClass('hidden');
    }, 1500);
}

function set_cookie(name, value) {
    document.cookie = name + "=" + value + "; path=/";
}

function read_cookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
    return null;
}

$(function() {
    window.zuul_graph_update_count = 0;
    window.zuul_sparkline_urls = {};
    update_timeout();

    $(document).on({
        'show.visibility': function() {
            window.zuul_enable_status_updates = true;
            update();
            update_graphs();
        },
        'hide.visibility': function() {
            window.zuul_enable_status_updates = false;
        }
    });

    $('#projects_filter').live('keyup change', function () {
        window.zuul_filter = $('#projects_filter').val().trim().split(',');
        window.zuul_filter = window.zuul_filter.filter(function(n){
            return n;
        });
        $.each($('div[project]'), function (idx, val) {
            val = $(val);
            var project = val.attr('project');
            if (is_hide_project(project)) {
                val.hide(100);
            } else {
                val.show(100);
            }
        });
    }).live('keyup', function () {
        $('a.save-filter')
            .removeClass('hidden')
            .live('click', function(e){
                e.preventDefault();
                $(this).addClass('hidden');
                save_filter();
            });
    });
    var cookie = read_cookie('zuul-project-filter');
    if(cookie)
        $('#projects_filter').val(cookie).change();
    cookie = read_cookie('zuul-expand-by-default');
    if(cookie)
        $('#expandByDefault').prop('checked', cookie == 'true' ? true : false);
});
