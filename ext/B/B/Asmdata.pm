#
#      Copyright (c) 1996-1999 Malcolm Beattie
#
#      You may distribute under the terms of either the GNU General Public
#      License or the Artistic License, as specified in the README file.
#
#
#
# This file is autogenerated from bytecode.pl. Changes made here will be lost.
#
package B::Asmdata;

our $VERSION = '1.00';

use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(%insn_data @insn_name @optype @specialsv_name);
our(%insn_data, @insn_name, @optype, @specialsv_name);

@optype = qw(OP UNOP BINOP LOGOP LISTOP PMOP SVOP PADOP PVOP LOOP COP);
@specialsv_name = qw(Nullsv &PL_sv_undef &PL_sv_yes &PL_sv_no pWARN_ALL pWARN_NONE);

# XXX insn_data is initialised this way because with a large
# %insn_data = (foo => [...], bar => [...], ...) initialiser
# I get a hard-to-track-down stack underflow and segfault.
$insn_data{comment} = [35, \&PUT_comment_t, "GET_comment_t"];
$insn_data{nop} = [10, \&PUT_none, "GET_none"];
$insn_data{ret} = [0, \&PUT_none, "GET_none"];
$insn_data{ldsv} = [1, \&PUT_svindex, "GET_svindex"];
$insn_data{ldop} = [2, \&PUT_opindex, "GET_opindex"];
$insn_data{stsv} = [3, \&PUT_U32, "GET_U32"];
$insn_data{stop} = [4, \&PUT_U32, "GET_U32"];
$insn_data{stpv} = [5, \&PUT_U32, "GET_U32"];
$insn_data{ldspecsv} = [6, \&PUT_U8, "GET_U8"];
$insn_data{newsv} = [7, \&PUT_U8, "GET_U8"];
$insn_data{newop} = [8, \&PUT_U8, "GET_U8"];
$insn_data{newopn} = [9, \&PUT_U8, "GET_U8"];
$insn_data{newpv} = [11, \&PUT_PV, "GET_PV"];
$insn_data{pv_cur} = [12, \&PUT_U32, "GET_U32"];
$insn_data{pv_free} = [13, \&PUT_none, "GET_none"];
$insn_data{sv_upgrade} = [14, \&PUT_U8, "GET_U8"];
$insn_data{sv_refcnt} = [15, \&PUT_U32, "GET_U32"];
$insn_data{sv_refcnt_add} = [16, \&PUT_I32, "GET_I32"];
$insn_data{sv_flags} = [17, \&PUT_U32, "GET_U32"];
$insn_data{xrv} = [18, \&PUT_svindex, "GET_svindex"];
$insn_data{xpv} = [19, \&PUT_none, "GET_none"];
$insn_data{xiv32} = [20, \&PUT_I32, "GET_I32"];
$insn_data{xiv64} = [21, \&PUT_IV64, "GET_IV64"];
$insn_data{xnv} = [22, \&PUT_NV, "GET_NV"];
$insn_data{xlv_targoff} = [23, \&PUT_U32, "GET_U32"];
$insn_data{xlv_targlen} = [24, \&PUT_U32, "GET_U32"];
$insn_data{xlv_targ} = [25, \&PUT_svindex, "GET_svindex"];
$insn_data{xlv_type} = [26, \&PUT_U8, "GET_U8"];
$insn_data{xbm_useful} = [27, \&PUT_I32, "GET_I32"];
$insn_data{xbm_previous} = [28, \&PUT_U16, "GET_U16"];
$insn_data{xbm_rare} = [29, \&PUT_U8, "GET_U8"];
$insn_data{xfm_lines} = [30, \&PUT_I32, "GET_I32"];
$insn_data{xio_lines} = [31, \&PUT_I32, "GET_I32"];
$insn_data{xio_page} = [32, \&PUT_I32, "GET_I32"];
$insn_data{xio_page_len} = [33, \&PUT_I32, "GET_I32"];
$insn_data{xio_lines_left} = [34, \&PUT_I32, "GET_I32"];
$insn_data{xio_top_name} = [36, \&PUT_pvcontents, "GET_pvcontents"];
$insn_data{xio_top_gv} = [37, \&PUT_svindex, "GET_svindex"];
$insn_data{xio_fmt_name} = [38, \&PUT_pvcontents, "GET_pvcontents"];
$insn_data{xio_fmt_gv} = [39, \&PUT_svindex, "GET_svindex"];
$insn_data{xio_bottom_name} = [40, \&PUT_pvcontents, "GET_pvcontents"];
$insn_data{xio_bottom_gv} = [41, \&PUT_svindex, "GET_svindex"];
$insn_data{xio_subprocess} = [42, \&PUT_U16, "GET_U16"];
$insn_data{xio_type} = [43, \&PUT_U8, "GET_U8"];
$insn_data{xio_flags} = [44, \&PUT_U8, "GET_U8"];
$insn_data{xcv_stash} = [45, \&PUT_svindex, "GET_svindex"];
$insn_data{xcv_start} = [46, \&PUT_opindex, "GET_opindex"];
$insn_data{xcv_root} = [47, \&PUT_opindex, "GET_opindex"];
$insn_data{xcv_gv} = [48, \&PUT_svindex, "GET_svindex"];
$insn_data{xcv_file} = [49, \&PUT_pvindex, "GET_pvindex"];
$insn_data{xcv_depth} = [50, \&PUT_I32, "GET_I32"];
$insn_data{xcv_padlist} = [51, \&PUT_svindex, "GET_svindex"];
$insn_data{xcv_outside} = [52, \&PUT_svindex, "GET_svindex"];
$insn_data{xcv_flags} = [53, \&PUT_U16, "GET_U16"];
$insn_data{av_extend} = [54, \&PUT_I32, "GET_I32"];
$insn_data{av_push} = [55, \&PUT_svindex, "GET_svindex"];
$insn_data{xav_fill} = [56, \&PUT_I32, "GET_I32"];
$insn_data{xav_max} = [57, \&PUT_I32, "GET_I32"];
$insn_data{xav_flags} = [58, \&PUT_U8, "GET_U8"];
$insn_data{xhv_riter} = [59, \&PUT_I32, "GET_I32"];
$insn_data{xhv_name} = [60, \&PUT_pvcontents, "GET_pvcontents"];
$insn_data{hv_store} = [61, \&PUT_svindex, "GET_svindex"];
$insn_data{sv_magic} = [62, \&PUT_U8, "GET_U8"];
$insn_data{mg_obj} = [63, \&PUT_svindex, "GET_svindex"];
$insn_data{mg_private} = [64, \&PUT_U16, "GET_U16"];
$insn_data{mg_flags} = [65, \&PUT_U8, "GET_U8"];
$insn_data{mg_pv} = [66, \&PUT_pvcontents, "GET_pvcontents"];
$insn_data{xmg_stash} = [67, \&PUT_svindex, "GET_svindex"];
$insn_data{gv_fetchpv} = [68, \&PUT_strconst, "GET_strconst"];
$insn_data{gv_stashpv} = [69, \&PUT_strconst, "GET_strconst"];
$insn_data{gp_sv} = [70, \&PUT_svindex, "GET_svindex"];
$insn_data{gp_refcnt} = [71, \&PUT_U32, "GET_U32"];
$insn_data{gp_refcnt_add} = [72, \&PUT_I32, "GET_I32"];
$insn_data{gp_av} = [73, \&PUT_svindex, "GET_svindex"];
$insn_data{gp_hv} = [74, \&PUT_svindex, "GET_svindex"];
$insn_data{gp_cv} = [75, \&PUT_svindex, "GET_svindex"];
$insn_data{gp_file} = [76, \&PUT_pvindex, "GET_pvindex"];
$insn_data{gp_io} = [77, \&PUT_svindex, "GET_svindex"];
$insn_data{gp_form} = [78, \&PUT_svindex, "GET_svindex"];
$insn_data{gp_cvgen} = [79, \&PUT_U32, "GET_U32"];
$insn_data{gp_line} = [80, \&PUT_U16, "GET_U16"];
$insn_data{gp_share} = [81, \&PUT_svindex, "GET_svindex"];
$insn_data{xgv_flags} = [82, \&PUT_U8, "GET_U8"];
$insn_data{op_next} = [83, \&PUT_opindex, "GET_opindex"];
$insn_data{op_sibling} = [84, \&PUT_opindex, "GET_opindex"];
$insn_data{op_ppaddr} = [85, \&PUT_strconst, "GET_strconst"];
$insn_data{op_targ} = [86, \&PUT_U32, "GET_U32"];
$insn_data{op_type} = [87, \&PUT_U16, "GET_U16"];
$insn_data{op_seq} = [88, \&PUT_U16, "GET_U16"];
$insn_data{op_flags} = [89, \&PUT_U8, "GET_U8"];
$insn_data{op_private} = [90, \&PUT_U8, "GET_U8"];
$insn_data{op_first} = [91, \&PUT_opindex, "GET_opindex"];
$insn_data{op_last} = [92, \&PUT_opindex, "GET_opindex"];
$insn_data{op_other} = [93, \&PUT_opindex, "GET_opindex"];
$insn_data{op_pmreplroot} = [94, \&PUT_opindex, "GET_opindex"];
$insn_data{op_pmreplrootgv} = [95, \&PUT_svindex, "GET_svindex"];
$insn_data{op_pmreplstart} = [96, \&PUT_opindex, "GET_opindex"];
$insn_data{op_pmnext} = [97, \&PUT_opindex, "GET_opindex"];
$insn_data{pregcomp} = [98, \&PUT_pvcontents, "GET_pvcontents"];
$insn_data{op_pmflags} = [99, \&PUT_U16, "GET_U16"];
$insn_data{op_pmpermflags} = [100, \&PUT_U16, "GET_U16"];
$insn_data{op_sv} = [101, \&PUT_svindex, "GET_svindex"];
$insn_data{op_padix} = [102, \&PUT_U32, "GET_U32"];
$insn_data{op_pv} = [103, \&PUT_pvcontents, "GET_pvcontents"];
$insn_data{op_pv_tr} = [104, \&PUT_op_tr_array, "GET_op_tr_array"];
$insn_data{op_redoop} = [105, \&PUT_opindex, "GET_opindex"];
$insn_data{op_nextop} = [106, \&PUT_opindex, "GET_opindex"];
$insn_data{op_lastop} = [107, \&PUT_opindex, "GET_opindex"];
$insn_data{cop_label} = [108, \&PUT_pvindex, "GET_pvindex"];
$insn_data{cop_stashpv} = [109, \&PUT_pvindex, "GET_pvindex"];
$insn_data{cop_file} = [110, \&PUT_pvindex, "GET_pvindex"];
$insn_data{cop_seq} = [111, \&PUT_U32, "GET_U32"];
$insn_data{cop_arybase} = [112, \&PUT_I32, "GET_I32"];
$insn_data{cop_line} = [113, \&PUT_U16, "GET_U16"];
$insn_data{cop_warnings} = [114, \&PUT_svindex, "GET_svindex"];
$insn_data{main_start} = [115, \&PUT_opindex, "GET_opindex"];
$insn_data{main_root} = [116, \&PUT_opindex, "GET_opindex"];
$insn_data{curpad} = [117, \&PUT_svindex, "GET_svindex"];
$insn_data{push_begin} = [118, \&PUT_svindex, "GET_svindex"];
$insn_data{push_init} = [119, \&PUT_svindex, "GET_svindex"];
$insn_data{push_end} = [120, \&PUT_svindex, "GET_svindex"];

my ($insn_name, $insn_data);
while (($insn_name, $insn_data) = each %insn_data) {
    $insn_name[$insn_data->[0]] = $insn_name;
}
# Fill in any gaps
@insn_name = map($_ || "unused", @insn_name);

1;

__END__

=head1 NAME

B::Asmdata - Autogenerated data about Perl ops, used to generate bytecode

=head1 SYNOPSIS

	use Asmdata;

=head1 DESCRIPTION

See F<ext/B/B/Asmdata.pm>.

=head1 AUTHOR

Malcolm Beattie, C<mbeattie@sable.ox.ac.uk>

=cut
