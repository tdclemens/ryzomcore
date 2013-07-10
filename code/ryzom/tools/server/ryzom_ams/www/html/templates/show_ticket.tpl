{block name=content}
<div class="row-fluid sortable ui-sortable">
    <div class="box span12">
        <div class="box-header well" data-original-title="">
            <h2><i class="icon-tags"></i> {$t_title}[ID#{$ticket_tId}] </h2>
            <div class="box-icon">
                <a href="#" class="btn btn-minimize btn-round"><i class="icon-chevron-up"></i></a>
                <a href="#" class="btn btn-close btn-round"><i class="icon-remove"></i></a>
            </div>
        </div>
        <div class="box-content">
            <div class="row-fluid">
                <legend>{$title}: {$ticket_title} </legend>
		<table class="table table-striped" >
		    <tbody>
			{foreach from=$ticket_replies item=reply}
			<tr>
			    <td>
				<p><span class="label label-info"><i class="icon-tag icon-white"></i> [ID#{$reply.tReplyId}] {$reply.timestamp}</span>
				{if $reply.permission eq '1'}
				<!-- <span class="label label-important"><strong></i>[User]:</strong></span>-->
				{else if $reply.permission eq '2'}
			        <span class="label label-important"><strong><i class="icon-star icon-white"></i>[CSR]</strong></span>
				{/if}
				<span class="label label-warning"><strong><i class="icon-user icon-white"></i>{$reply.author}</strong></span></p>
				<p><pre>{$reply.replyContent}</pre></p>
			    </td>
			</tr>
			{/foreach}
			<tr>
			    <td>
				<form id="reply" class="form-vertical" method="post" action="index.php">
				<legend>{$t_reply}:</legend>
				<div class="control-group">
				    <label class="control-label">{$t_fill}</label>
				    <div class="controls">
					<div class="input-prepend">
					    <textarea rows="6" class="span12" id="Content" name="Content"></textarea>
					</div>
				    </div>
				</div>
				<input type="hidden" name="function" value="reply_on_ticket">
				<input type="hidden" name="ticket_id" value="{$ticket_id}">
				<div class="control-group">
				    <label class="control-label"></label>
				    <div class="controls">
					<button type="submit" class="btn btn-primary" >{$t_send}</button>
				    </div>
				</div>
				</form>
			    </td>
			</tr>
		    </tbody>
		</table>
	    </div>                   
        </div>
    </div><!--/span-->
</div><!--/row-->
{/block}
	
