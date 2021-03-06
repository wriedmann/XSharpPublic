﻿////////////////////////////////////////////////////////////////////////////////
// AssemblyInfo.prg

#using System.Reflection
#using System.Runtime.InteropServices
#using System.Security

#include "..\..\SharedSource\BuildNumber.h" 
#include "..\..\SharedSource\RuntimeNames.h"  

[assembly: AssemblyTitleAttribute( "VO-Compatible Win32 API Library" )]
[assembly: AssemblyDescriptionAttribute( "VO-Compatible Win32 API Functions and Structures" )]
[assembly: AssemblyConfigurationAttribute( ASSEMBLY_CONFIGURATION )]
[assembly: AssemblyCompanyAttribute( COMPANY_NAME )]
[assembly: AssemblyProductAttribute( PRODUCT_NAME )]
[assembly: AssemblyCopyrightAttribute( COPYRIGHT_STR )]
[assembly: ComVisibleAttribute( FALSE )]
[assembly: ClsCompliant( FALSE )]
//[assembly: AllowPartiallyTrustedCallersAttribute()]
[assembly: AssemblyVersionAttribute( VERSION_NUMBER_STR )]
[assembly: AssemblyFileVersionAttribute( FILEVERSION_NUMBER_STR )]
[assembly: AssemblyInformationalVersionAttribute( VERSION_NUMBER_STR )]
#ifdef __XSHARP__
[assembly: ImplicitNamespaceAttribute( VULCAN_VOSDK_NAMESPACE )]
#else
[assembly: Vulcan.VulcanImplicitNamespaceAttribute( VULCAN_VOSDK_NAMESPACE )]
#endif

[module: UnverifiableCodeAttribute()]
[assembly: AllowPartiallyTrustedCallersAttribute()]
#ifdef __CLR4__
[assembly: SecurityRulesAttribute (SecurityRuleSet.Level1)]
#endif 

