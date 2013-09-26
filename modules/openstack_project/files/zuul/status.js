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

function create_graph(pipeline) {
    var count = 0;
    var pipeline_max_graph_columns = 1;
    $.each(pipeline['change_queues'], function(change_queue_i, change_queue) {
        var graph = [];
        var max_graph_columns = 1;
        var changes = [];
        var last_graph_length = 0;
        $.each(change_queue['heads'], function(head_i, head) {
            $.each(head, function(change_i, change) {
                changes[change['id']] = change;
                change['_graph_position'] = change_i;
            });
        });
        $.each(change_queue['heads'], function(head_i, head) {
            $.each(head, function(change_i, change) {
                count += 1;
                var idx = graph.indexOf(change['id']);
                if (idx > -1) {
                    change['_graph_index'] = idx;
                    remove(graph, idx);
                } else {
                    change['_graph_index'] = 0;
                }
                change['_graph_branches'] = [];
                change['_graph'] = [];
                change['items_behind'].sort(function(a, b) {
                    return changes[b]['_graph_position'] - changes[a]['_graph_position'];
                });
                $.each(change['items_behind'], function(i, id) {
                    graph.push(id);
                    if (last_graph_length>0 && graph.length>last_graph_length)
                        change['_graph_branches'].push(graph.length-1);
                });
                if (graph.length > max_graph_columns) {
                    max_graph_columns = graph.length;
                }
                if (graph.length > pipeline_max_graph_columns) {
                    pipeline_max_graph_columns = graph.length;
                }
                change['_graph'] = graph.slice(0);  // make a copy
                last_graph_length = graph.length;
            });
        });
        change_queue['_graph_columns'] = max_graph_columns;
    });
    pipeline['_graph_columns'] = pipeline_max_graph_columns;
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
                "color(stats.gauges.zuul.pipeline."+pipeline_name+".current_changes, '6b8182')",
            ],
        });
    }
    return window.zuul_sparkline_urls[pipeline_name];
}

function format_pipeline(data) {
    var count = create_graph(data);
    var width = (16 * data['_graph_columns']) + 300;
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
            html += '<table>'
            $.each(head, function(change_i, change) {
                html += format_change(change, change_queue);
            });
            html += '</table></div>'
        });
    });

    html += '</div>';
    return html;
}

function safe_id(id) {
    return id.replace(',', '_');
}

function format_change(change, change_queue) {
    var html = '<tr>';

    for (var i=0; i<change_queue['_graph_columns']; i++) {
        var cls = 'graph';
        if (i < change['_graph'].length && change['_graph'][i] !== null) {
            cls += ' line';
        }
        html += '<td class="'+cls+'">';
        if (i == change['_graph_index']) {
            if (change['failing_reasons'] && change['failing_reasons'].length > 0) {
                html += '<img src="red.png" title="Failing because '+
                    change['failing_reasons'].join(', ')+'"/>';
            } else {
                html += '<img src="green.png" title="Succeeding"/>';
            }
        }
        if (change['_graph_branches'].indexOf(i) != -1) {
            if (change['_graph_branches'].indexOf(i) == change['_graph_branches'].length-1)
                html += '<img src="line-angle.png"/>';
            else
                html += '<img src="line-t.png"/>';
        }
        html += '</td>';
    }

    html += '<td class="change-container">';
    html += '<div class="change" id="'+safe_id(change['id'])+'"><div class="header">';

    html += '<span class="project">' + change['project'] + '</span>';
    var id = change['id'];
    var url = change['url'];
    if (id !== "None") {
        if (id.length == 40) {
            id = id.substr(0,7);
        }
        html += '<span class="changeid">';
        if (url !== null) {
            html += '<a href="'+url+'">';
        }
        html += id;
        if (url !== null) {
            html += '</a>';
        }
    }

    html += '</span><span class="time">';
    html += format_time(change['remaining_time'], true);
    html += '</span></div><div class="jobs">';

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
        html += '<span class="job">';
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
        html += '</span>';
    });

    html += '</div></div></td></tr>';
    return html;
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
        })
    });
});
