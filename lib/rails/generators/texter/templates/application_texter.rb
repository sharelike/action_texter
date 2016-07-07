<% module_namespacing do -%>
class ApplicationTexter < ActionTexter::Base
  default from: 'from@example.com'
  layout 'texter'
end
<% end %>
