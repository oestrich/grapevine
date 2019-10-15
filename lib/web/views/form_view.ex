defmodule Web.FormView do
  use Web, :view

  @doc """
  Label helper to optionally override the label text
  """
  def field_label(form, field, opts) do
    case Keyword.get(opts, :label) do
      nil ->
        label(form, field, class: "col-md-3")

      text ->
        label(form, field, text, class: "col-md-3")
    end
  end

  @doc """
  Generate a text field, styled properly
  """
  def text_field(form, field, opts \\ [], dopts \\ []) do
    opts = Keyword.merge(opts, dopts)
    text_opts = Keyword.take(opts, [:type, :value, :autofocus])

    content_tag(:div, class: form_group_classes(form, field)) do
      [
        field_label(form, field, opts),
        content_tag(:div, class: "col-md-9") do
          [
            text_input(form, field, Keyword.merge([class: "form-control"], text_opts)),
            error_tag(form, field),
            Keyword.get(opts, :do, "")
          ]
        end
      ]
    end
  end

  @doc """
  Generate a text field, styled properly
  """
  def password_field(form, field, opts \\ [], dopts \\ []) do
    opts = Keyword.merge(opts, dopts)
    text_opts = Keyword.take(opts, [:value, :rows])

    content_tag(:div, class: form_group_classes(form, field)) do
      [
        field_label(form, field, opts),
        content_tag(:div, class: "col-md-9") do
          [
            password_input(form, field, Keyword.merge([class: "form-control"], text_opts)),
            error_tag(form, field),
            Keyword.get(opts, :do, "")
          ]
        end
      ]
    end
  end

  @doc """
  Generate a number field, styled properly
  """
  def number_field(form, field, opts \\ [], dopts \\ []) do
    opts = Keyword.merge(opts, dopts)
    number_opts = Keyword.take(opts, [:placeholder, :min, :max])

    content_tag(:div, class: form_group_classes(form, field)) do
      [
        field_label(form, field, opts),
        content_tag(:div, class: "col-md-9") do
          [
            number_input(form, field, Keyword.merge([class: "form-control"], number_opts)),
            error_tag(form, field),
            Keyword.get(opts, :do, "")
          ]
        end
      ]
    end
  end

  @doc """
  Generate a textarea field, styled properly
  """
  def textarea_field(form, field, opts \\ [], dopts \\ []) do
    opts = Keyword.merge(opts, dopts)
    textarea_opts = Keyword.take(opts, [:value, :rows])

    content_tag(:div, class: form_group_classes(form, field)) do
      [
        field_label(form, field, opts),
        content_tag(:div, class: "col-md-9") do
          [
            textarea(form, field, Keyword.merge([class: "form-control"], textarea_opts)),
            error_tag(form, field),
            Keyword.get(opts, :do, "")
          ]
        end
      ]
    end
  end

  @doc """
  Generate a checkbox field, styled properly
  """
  def checkbox_field(form, field, opts \\ [], dopts \\ []) do
    opts = Keyword.merge(opts, dopts)

    content_tag(:div, class: "form-group form-check row") do
      content_tag(:div, class: "col-md-9 offset-md-3") do
        [
          label(form, field) do
            [checkbox(form, field, class: "form-check-input"), " ", opts[:label]]
          end,
          error_tag(form, field),
          Keyword.get(opts, :do, "")
        ]
      end
    end
  end

  @doc """
  Generate a file field, styled properly
  """
  def file_field(form, field, opts \\ [], dopts \\ []) do
    opts = Keyword.merge(opts, dopts)

    content_tag(:div, class: form_group_classes(form, field)) do
      [
        field_label(form, field, opts),
        content_tag(:div, class: "col-md-9") do
          [
            file_input(form, field, class: "form-control"),
            error_tag(form, field),
            Keyword.get(opts, :do, "")
          ]
        end
      ]
    end
  end

  defp form_group_classes(form, field) do
    case Keyword.has_key?(form.errors, field) do
      true ->
        "form-group row has-error"

      false ->
        "form-group row"
    end
  end
end
