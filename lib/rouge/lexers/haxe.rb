# -*- coding: utf-8 -*- #

module Rouge
  module Lexers
    class Haxe < RegexLexer
      title "Haxe"
      desc "Haxe Cross-platform Toolkit (http://haxe.org)"

      tag 'haxe'
      aliases 'hx', 'Haxe', 'haxe'
      filenames '*.hx'
      mimetypes 'text/haxe', 'text/x-haxe', 'text/x-hx'

      state :comments_and_whitespace do
        rule /\s+/, Text
        rule %r(//.*?$), Comment::Single
        rule %r(/\*.*?\*/)m, Comment::Multiline
      end

      state :expr_start do
        mixin :comments_and_whitespace

        rule %r(/) do
          token Str::Regex
          goto :regex
        end

        rule /[{]/, Punctuation, :object

        rule //, Text, :pop!
      end

      state :regex do
        rule %r(/) do
          token Str::Regex
          goto :regex_end
        end

        rule %r([^/]\n), Error, :pop!

        rule /\n/, Error, :pop!
        rule /\[\^/, Str::Escape, :regex_group
        rule /\[/, Str::Escape, :regex_group
        rule /\\./, Str::Escape
        rule %r{[(][?][:=<!]}, Str::Escape
        rule /[{][\d,]+[}]/, Str::Escape
        rule /[()?]/, Str::Escape
        rule /./, Str::Regex
      end

      state :regex_end do
        rule /[gim]+/, Str::Regex, :pop!
        rule(//) { pop! }
      end

      state :regex_group do
        # specially highlight / in a group to indicate that it doesn't
        # close the regex
        rule /\//, Str::Escape

        rule %r([^/]\n) do
          token Error
          pop! 2
        end

        rule /\]/, Str::Escape, :pop!
        rule /\\./, Str::Escape
        rule /./, Str::Regex
      end

      state :bad_regex do
        rule /[^\n]+/, Error, :pop!
      end

      def self.keywords
					@keywords ||= Set.new %w(
							break case cast catch class continue default do else enum false for
							function if import interface macro new null override package private
							public return switch this throw true try untyped while
					)
			end

			def self.imports
					@imports ||= Set.new %w(
							import using
					)
			end

			def self.declarations
					@declarations ||= Set.new %w(
							abstract dynamic extern extends implements inline
							static typedef var
					)
			end

			def self.cond_keywords
					@cond_keywords ||= Set.new %w(
							if else elseif end
					)
			end

			def self.reserved
					@reserved ||= Set.new %w(
							super trace inline build autoBuild enum
					)
			end

			def self.constants
					@constants ||= Set.new %w(true false null)
			end
      def self.builtins
        @builtins ||= %w(
          Void Dynamic Math Class Any Float Int UInt String StringTools Sys
          EReg isNaN parseFloat parseInt this Array Map Date DateTools Bool
          Lambda Reflect Std File FileSystem
        )
      end

      id = /[$a-zA-Z_][a-zA-Z0-9_]*/

      state :root do
        rule /\A\s*#!.*?\n/m, Comment::Preproc, :statement
        rule /\n/, Text, :statement
        rule %r((?<=\n)(?=\s|/|<!--)), Text, :expr_start
        mixin :comments_and_whitespace
        rule %r(\+\+ | -- | ~ | && | \|\| | \\(?=\n) | << | >>>? | ===
               | !== )x,
          Operator, :expr_start
        rule %r([:-<>+*%&|\^/!=]=?), Operator, :expr_start
        rule /[(\[,]/, Punctuation, :expr_start
        rule /;/, Punctuation, :statement
        rule /[)\].]/, Punctuation

        rule /[?]/ do
          token Punctuation
          push :ternary
          push :expr_start
        end

        rule /[{}]/, Punctuation, :statement

        rule id do |m|
          if self.class.keywords.include? m[0]
            token Keyword
            push :expr_start
          elsif self.class.imports.include? m[0]
            token Keyword
            push :namespace
          elsif self.class.declarations.include? m[0]
            token Keyword::Declaration
            push :expr_start
          #elsif self.class.cond_keywords.include? /^#{m[0]}\b/
          #  token Comment::Preproc
          elsif self.class.reserved.include? m[0]
            token Keyword::Reserved
          elsif self.class.constants.include? m[0]
            token Keyword::Constant
          elsif self.class.builtins.include? m[0]
            token Name::Builtin
          else
            token Name::Other
          end
        end

        rule /\-?[0-9][0-9]*\.[0-9]+([eE][0-9]+)?[fd]?/, Num::Float
        rule /0x[0-9a-fA-F]+/, Num::Hex
        rule /\-?[0-9]+/, Num::Integer
        rule /"(\\\\|\\"|[^"])*"/, Str::Double
        rule /'(\\\\|\\'|[^'])*'/, Str::Single
      end

      # braced parts that aren't object literals
      state :statement do
        rule /(#{id})(\s*)(:)/ do
          groups Name::Label, Text, Punctuation
        end

        rule /[{}]/, Punctuation

        mixin :expr_start
      end

      # object literals
      state :object do
        mixin :comments_and_whitespace
        rule /[}]/ do
          token Punctuation
          goto :statement
        end

        rule /(#{id})(\s*)(:)/ do
          groups Name::Attribute, Text, Punctuation
          push :expr_start
        end

        rule /:/, Punctuation
        mixin :root
      end

      # ternary expressions, where <id>: is not a label!
      state :ternary do
        rule /:/ do
          token Punctuation
          goto :expr_start
        end

        mixin :root
      end
    end
  end
end
