<%@ page import="org.mskcc.portal.servlet.PatientView" %>
<%@ page import="org.mskcc.portal.servlet.MutationsJSON" %>
<%@ page import="org.mskcc.cgds.dao.DaoMutSig" %>


<style type="text/css" title="currentStyle"> 
        @import "css/data_table_jui.css";
        @import "css/data_table_ColVis.css";
        .ColVis {
                float: left;
                margin-bottom: 0
        }
        .mutation-summary-table-name {
                float: left;
                font-weight: bold;
                font-size: 130%;
        }
        .mutation-show-more {
            float: left;
        }
        .dataTables_length {
                width: auto;
                float: right;
        }
        .dataTables_info {
                width: auto;
                float: right;
        }
        .div.datatable-paging {
                width: auto;
                float: right;
        }
</style>

<script type="text/javascript">
    
    jQuery.fn.dataTableExt.oSort['mutsig-col-asc']  = function(x,y) {
        if (x==null) {
            return y==null ? 0 : 1;
        }
        if (y==null)
            return -1;
	return ((x < y) ? -1 : ((x > y) ?  1 : 0));
    };

    jQuery.fn.dataTableExt.oSort['mutsig-col-desc'] = function(x,y) {
        if (isNaN(x)) {
            return y==null ? 0 : 1;
        }
        if (y==null)
            return -1;
	return ((x < y) ? 1 : ((x > y) ?  -1 : 0));
    };
    
    var placeHolder = <%=Boolean.toString(showPlaceHoder)%>;
    function buildMutationsDataTable(mutations, table_id, sDom, iDisplayLength) {
        var oTable = $(table_id).dataTable( {
                "sDom": sDom, // selectable columns
                "bJQueryUI": true,
                "bDestroy": true,
                "aaData": mutations,
                "aoColumnDefs":[
                    {// event id
                        "bVisible": false,
                        "aTargets": [ 0 ]
                    },
                    {// clinical trials
                        "bVisible": placeHolder,
                        "aTargets": [ 6 ]
                    },
                    {// note
                        "bVisible": placeHolder,
                        "aTargets": [ 7 ]
                    },
                    {// mutsig
                        "sType": "mutsig-col",
                        "bVisible": false,
                        "aTargets": [ 8 ]
                    },
                    {// in overview
                        "bVisible": false,
                        "aTargets": [ 9 ]
                    }
                ],
                "aaSorting": [[8,'asc']],
                "oLanguage": {
                    "sInfo": "&nbsp;&nbsp;(_START_ to _END_ of _TOTAL_)&nbsp;&nbsp;",
                    "sInfoFiltered": "",
                    "sLengthMenu": "Show _MENU_ per page"
                },
                "iDisplayLength": iDisplayLength,
                "aLengthMenu": [[5,10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"]]
        } );

        // help
        $('.mutations_help').tipTip();

        $(table_id).css("width","100%");
        return oTable;
    }
    
    function updateMutationContext(mutationContext, geneContext, oTable) {
        var nRows = oTable.fnSettings().fnRecordsTotal();
        for (var row=0; row<nRows; row++) {
            var eventId = oTable.fnGetData(row, 0);
            var mutContext = mutationContext[eventId];
            oTable.fnUpdate(mutContext, row, 5, false);
        }
        oTable.fnDraw();
        oTable.css("width","100%");
    }
    
    function loadContextData(mutations, mut_table, mut_summary_table) {
        var eventIds = getEventIdString(mutations);
        
        var params = {
            <%=MutationsJSON.CMD%>:'<%=MutationsJSON.GET_CONTEXT_CMD%>',
            <%=PatientView.MUTATION_PROFILE%>:'<%=mutationProfile.getStableId()%>',
            <%=MutationsJSON.MUTATION_EVENT_ID%>:eventIds
        };
        
        $.post("mutations.json", 
            params,
            function(context){
                var mutationContext = context[0]['<%=MutationsJSON.MUTATION_CONTEXT%>'];
                var geneContext =  context[0]['<%=MutationsJSON.GENE_CONTEXT%>'];
                updateMutationContext(mutationContext, geneContext, mut_table);
                updateMutationContext(mutationContext, geneContext, mut_summary_table);
            }
            ,"json"
        );
    }
    
    $(document).ready(function(){
        $('#mutation_wrapper_table').hide();
        var params = {
            <%=PatientView.PATIENT_ID%>:'<%=patient%>',
            <%=PatientView.MUTATION_PROFILE%>:'<%=mutationProfile.getStableId()%>',
            <%=PatientView.NUM_CASES_IN_SAME_STUDY%>:'<%=numPatientInSameStudy%>'
        };
                        
        $.post("mutations.json", 
            params,
            function(mutations){
                // mutations
                var mut_table = buildMutationsDataTable(mutations, '#mutation_table', '<"H"fr>t<"F"<"datatable-paging"pil>>', 100);
                $('#mutation_wrapper_table').show();
                $('#mutation_wait').remove();
                
                $('#similar_patients_table').trigger('mutations-built');
                
                // summary table
                var mut_sumary = buildMutationsDataTable(mutations, '#mutation_summary_table', '<"H"<"mutation-summary-table-name">fr>t<"F"<"mutation-show-more"><"datatable-paging"pil>>', 5);
                $('.mutation-summary-table-name').html('Mutations of Interest');
                $('.mutation-show-more').html("<a href='#mutations' id='switch-to-mutations-tab' title='Show more mutations of this patient'>Show more mutations</a>");
                $('#switch-to-mutations-tab').click(function () {
                    switchToTab('mutations');
                    return false;
                });
                mut_sumary.fnFilter('true', 9);
                $('#mutation_summary_wrapper_table').show();
                $('#mutation_summary_wait').remove();
                
                loadContextData(mutations, mut_table, mut_sumary);
            }
            ,"json"
        );
    });
</script>

<div id="mutation_wait"><img src="images/ajax-loader.gif"/></div>

<table cellpadding="0" cellspacing="0" border="0" id="mutation_wrapper_table" width="100%">
    <tr>
        <td>
            <table cellpadding="0" cellspacing="0" border="0" class="display" id="mutation_table">
                <%@ include file="mutations_table_template.jsp"%>
            </table>
        </td>
    </tr>
</table>