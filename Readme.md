A piece of error message output by g++:
```
../src/tools/generic/satisfy.hpp:9:37: note: the expression ‘Requirement<Type>::value [with Requirement = newlir::is_x86_instr; Type = newlir::PhiInstr]’ evaluated to ‘false’
    9 |         requires(Requirement<Type>::value) struct satisfy {
      |                 ~~~~~~~~~~~~~~~~~~~~^~~~~~
../src/tools/generic/satisfy.hpp: In instantiation of ‘struct each_variant_alternative_satisfies<std::variant<newlir::LeaveInstr, newlir::RetInstr, newlir::PopInstr, newlir::PushInstr, newlir::CallInstr, newlir::UnaryNotInstr, newlir::UnaryNegInstr, newlir::PseudoReadInstr, newlir::PseudoWriteInstr, newlir::JmpInstr, newlir::JeInstr, newlir::JneInstr, newlir::JlInstr, newlir::JnlInstr, newlir::JleInstr, newlir::JnleInstr, newlir::JgInstr, newlir::JngInstr, newlir::JgeInstr, newlir::JngeInstr, newlir::BinaryNotInstr, newlir::BinaryNegInstr, newlir::LeaInstr, newlir::MovInstr, newlir::CmpInstr, newlir::BinaryAddInstr, newlir::BinarySubInstr, newlir::BinaryAndInstr, newlir::BinaryOrInstr, newlir::BinaryShlInstr, newlir::BinaryShrInstr, newlir::BinaryXorInstr, newlir::BinaryIMulInstr, newlir::BinaryIDivInstr, newlir::TernaryAddInstr, newlir::TernarySubInstr, newlir::TernaryAndInstr, newlir::TernaryOrInstr, newlir::TernaryShlInstr, newlir::TernaryShrInstr, newlir::TernaryXorInstr, newlir::TernaryIMulInstr, newlir::TernaryIDivInstr, newlir::PhiInstr>, newlir::is_printable_x86_instr>’:
```

After being folded, it became:
```
../src/tools/generic/satisfy.hpp:9:37: note: the expression ‘Requirement<Type>::value [with Requirement = newlir::is_x86_instr;...]’ evaluated to ‘false’
    9 |         requires(Requirement<Type>::value) struct satisfy {
      |                 ~~~~~~~~~~~~~~~~~~~~^~~~~~
../src/tools/generic/satisfy.hpp: In instantiation of ‘struct each_variant_alternative_satisfies<std::variant<newlir::LeaveInstr, newlir::RetInstr, ne...>, newlir::is_printable_x86_instr>’:
```

Available commands:
```
fold-template-error-fold-all

fold-template-error-unfold-all

fold-template-error-toggle-all
```

Recommanded usage: 
```
(add-hook 'compilation-finish-functions
          (lambda (buffer message)
            (fold-template-error-fold-all)))
```
