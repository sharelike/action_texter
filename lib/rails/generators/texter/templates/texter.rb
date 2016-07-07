<% module_namespacing do -%>
class <%= class_name %>Texter < ApplicationTexter
<% actions.each do |action| -%>

  def <%= action %>
    @greeting = "Hi"

    text to: "+886900000000"
  end
<% end -%>
end
<% end -%>
