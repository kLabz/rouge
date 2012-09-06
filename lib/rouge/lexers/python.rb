module Rouge
  module Lexers
    class Python < RegexLexer
      tag 'python'
      aliases 'py'
      extensions 'py'

      keywords = %w(
        assert break continue del elif else except exec
        finally for global if lambda pass print raise
        return try while yield as with
      )

      builtins = %w(
        __import__ abs all any apply basestring bin bool buffer
        bytearray bytes callable chr classmethod cmp coerce compile
        complex delattr dict dir divmod enumerate eval execfile exit
        file filter float frozenset getattr globals hasattr hash hex id
        input int intern isinstance issubclass iter len list locals
        long map max min next object oct open ord pow property range
        raw_input reduce reload repr reversed round set setattr slice
        sorted staticmethod str sum super tuple type unichr unicode
        vars xrange zip
      )

      builtins_pseudo = %w(self None Ellipsis NotImplemented False True)

      exceptions = %w(
        ArithmeticError AssertionError AttributeError
        BaseException DeprecationWarning EOFError EnvironmentError
        Exception FloatingPointError FutureWarning GeneratorExit IOError
        ImportError ImportWarning IndentationError IndexError KeyError
        KeyboardInterrupt LookupError MemoryError NameError
        NotImplemented NotImplementedError OSError OverflowError
        OverflowWarning PendingDeprecationWarning ReferenceError
        RuntimeError RuntimeWarning StandardError StopIteration
        SyntaxError SyntaxWarning SystemError SystemExit TabError
        TypeError UnboundLocalError UnicodeDecodeError
        UnicodeEncodeError UnicodeError UnicodeTranslateError
        UnicodeWarning UserWarning ValueError VMSError Warning
        WindowsError ZeroDivisionError
      )

      identifier =        /[a-z_][a-z0-9_]*/i
      dotted_identifier = /[a-z_.][a-z0-9_.]*/i
      state :root do
        rule /\n+/m, 'Text'
        rule /^(\s*)([rRuU]{,2}""".*?""")/m do
          group 'Text'
          group 'Literal.String.Doc'
        end

        rule /[^\S\n]+/, 'Text'
        rule /#.*$/, 'Comment'
        rule /[\[\]{}:(),;]/, 'Punctuation'
        rule /\\\n/, 'Text'
        rule /\\/, 'Text'

        rule /(in|is|and|or|not)\b/, 'Operator.Word'
        rule /!=|==|<<|>>|[-~+\/*%=<>&^|.]/, 'Operator'

        rule /(?:#{keywords.join('|')})\b/, 'Keyword'

        rule /(def)((?:\s|\\\s)+)/ do
          group 'Keyword' # def
          group 'Text' # whitespae
          push :funcname
        end

        rule /(class)((?:\s|\\\s)+)/ do
          group 'Keyword'
          group 'Text'
          push :classname
        end

        rule /(from)((?:\s|\\\s)+)/ do
          group 'Keyword.Namespace'
          group 'Text'
          push :fromimport
        end

        rule /(import)((?:\s|\\\s)+)/ do
          group 'Keyword.Namespace'
          group 'Text'
          push :import
        end

        # using negative lookbehind so we don't match property names
        rule /(?<!\.)(?:#{builtins.join('|')})/, 'Name.Builtin'
        rule /(?<!\.)(?:#{builtins_pseudo.join('|')})/, 'Name.Builtin.Pseudo'

        # TODO: not in python 3
        rule /`.*?`/, 'Literal.String.Backtick'
        rule /(?:r|ur|ru)"""/i, 'Literal.String', :tdqs
        rule /(?:r|ur|ru)'''/i, 'Literal.String', :tsqs
        rule /(?:r|ur|ru)"/i,   'Literal.String', :dqs
        rule /(?:r|ur|ru)'/i,   'Literal.String', :sqs
        rule /u?"""/i,          'Literal.String', :escape_tdqs
        rule /u?'''/i,          'Literal.String', :escape_tsqs
        rule /u?"/i,            'Literal.String', :escape_dqs
        rule /u?'/i,            'Literal.String', :escape_sqs

        rule /@#{dotted_identifier}/i, 'Name.Decorator'
        rule identifier, 'Name'

        rule /(\d+\.\d*|\d*\.\d+)(e[+-]?[0-9]+)?/i, 'Literal.Number.Float'
        rule /\d+e[+-]?[0-9]+/i, 'Literal.Number.Float'
        rule /0[0-7]+/, 'Literal.Number.Oct'
        rule /0x[a-f0-9]+/i, 'Literal.Number.Hex'
        rule /\d+L/, 'Literal.Number.Integer.Long'
        rule /\d+/, 'Literal.Number.Integer'
      end

      state :funcname do
        rule identifier, 'Name.Function', :pop!
      end

      state :classname do
        rule identifier, 'Name.Class', :pop!
      end

      state :import do
        # non-line-terminating whitespace
        rule /(?:[ \t]|\\\n)+/, 'Text'

        rule /as\b/, 'Keyword.Namespace'
        rule /,/, 'Operator'
        rule dotted_identifier, 'Name.Namespace'
        rule(//) { pop! } # anything else -> go back
      end

      state :fromimport do
        # non-line-terminating whitespace
        rule /(?:[ \t]|\\\n)+/, 'Text'

        rule /import\b/, 'Keyword.Namespace', :pop!
        rule dotted_identifier, 'Name.Namespace'
      end

      state :strings do
        rule /%(\([a-z0-9_]+\))?[-#0 +]*([0-9]+|[*])?(\.([0-9]+|[*]))?/i, 'Literal.String.Interpol'
        rule /[^\\'"%\n]+/, 'Literal.String'
      end

      state :nl do
        rule /\n/, 'Literal.String'
      end

      state :dqs do
        rule /"/, 'Literal.String', :pop!
        rule /\\\\|\\"|\\\n/, 'Literal.String.Escape'
        mixin :strings
      end

      state :sqs do
        rule /'/, 'Literal.String', :pop!
        rule /\\\\|\\'|\\\n/, 'Literal.String.Escape'
        mixin :strings
      end

      state :tdqs do
        rule /"""/, 'Literal.String', :pop!
        mixin :strings
        mixin :nl
      end

      state :tsqs do
        rule /'''/, 'Literal.String', :pop!
        mixin :strings
        mixin :nl
      end

      %w(tdqs tsqs dqs sqs).each do |qtype|
        state :"escape_#{qtype}" do
          mixin :escape
          mixin :"#{qtype}"
        end
      end
    end
  end
end