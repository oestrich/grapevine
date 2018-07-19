defmodule Web.DocView do
  use Web, :view

  def flag_header(flag_id, flag_name) do
    content_tag(:h3, id: flag_id) do
      link(to: "##{flag_id}") do
        [flag_name, " (", content_tag(:code, flag_id), ") ", content_tag(:i, "", class: "fas fa-link")]
      end
    end
  end

  def event_header(event_name) do
    id = String.replace(event_name, "/", "-")

    content_tag(:h4, id: id) do
      link(to: "##{id}") do
        [event_name, content_tag(:i, "", class: "fas fa-link")]
      end
    end
  end
end
