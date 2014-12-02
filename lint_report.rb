module GDUnused
  def lint_report(project_id)
    require 'gooddata'
    require 'prawn'

    Prawn::Document.generate("hello.pdf") do
      text "Hello World!"
    end
  end
end
