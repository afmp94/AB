module Leads::StatsHelper

  def display_lead_slats(lead, page=nil)
    state = lead.state
    contacted_status = lead.contacted_status
    if state != "claimed"
      time = time_since_received(lead)
      label_text = "Unclaimed"
      label_color = "danger"
      time_block = (time == " - ") ? " " : slat_data_block(time, "Lead Received")
    elsif contacted_status == 0
      label_text = "Not Contacted"
      label_color = "warning"
      time = time_since_received(lead)
      time_block = html_for_time_block(time, page)
    else
      if contacted_status == 1
        label_text = "Attempted"
        label_color = "success"
      elsif contacted_status == 3
        label_text = "Contacted"
        label_color = "success"
      elsif contacted_status == 2
        label_text = "Awaiting Client Response"
        label_color = "success"
      else
        label_text = " - "
        label_color = "neutral"
      end
      time       = elapsed_time_before_contacted(lead)
      time_block = html_for_time_block(time, page)
    end
    label_block = html_for_label_block(label_color, label_text, page)
    label_block + time_block
  end

  private

  def html_for_time_block(time, page)
    return  " " if time == " - "

    case page
    when nil
      "<div class='data inline-block float-left'>
         <h4>#{time}</h4>
         <p class='dim-el'>Time to contact</p>
       </div><!-- /data -->"
    when "dashboard"
      "<div class='data inline-block float-left'>
         <h7>#{time}</h7>
         <p class='dim-el'>Time to contact</p>
       </div><!-- /data -->"
    end
  end

  def html_for_label_block(label_color, label_text, page)
    case page
    when nil
      "<div class='data inline-block float-left txl'>
         <h3>
           <span class='label label-#{label_color}'><strong>#{label_text}</strong></span>
         </h3>
       </div><!-- /data -->"
    when "dashboard"
      "<div class='data inline-block float-left'>
         <h3 class='margin-top-minus-eight'><span class='label label-#{label_color}' class='font-size-62-percent'><strong>#{label_text}</strong></span>
         </h3>
       </div><!-- /data -->"
    end
  end

end
