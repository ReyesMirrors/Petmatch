import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/adoption_repository.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/adoption_usecases.dart';

// Events
abstract class AdoptionEvent extends Equatable { @override List<Object?> get props => []; }
class LoadRequestsEvent extends AdoptionEvent { final String uid; final bool asPublicador; LoadRequestsEvent(this.uid, {this.asPublicador = false}); }
class RequestAdoptionE extends AdoptionEvent { final String petId, petNombre, adoptanteId, publicadorId, mensaje, motivo, experiencia, hogar, otrosDetalles; RequestAdoptionE(this.petId, this.petNombre, this.adoptanteId, this.publicadorId, this.mensaje, this.motivo, this.experiencia, this.hogar, this.otrosDetalles); }
class UpdateStatusEvent extends AdoptionEvent { final String reqId; final AdoptionStatus status; UpdateStatusEvent(this.reqId, this.status); }
class DonateEvent extends AdoptionEvent { final String petId, donorId, donorNombre, nequiReceptor, nequiDonador, motivo; final double monto; DonateEvent(this.petId, this.donorId, this.donorNombre, this.monto, this.nequiReceptor, this.nequiDonador, this.motivo); }
class ConfirmDonationEvent extends AdoptionEvent { final String donationId; ConfirmDonationEvent(this.donationId); }
class SendMessageEvent extends AdoptionEvent { final String chatId, senderId, receiverId, texto; SendMessageEvent(this.chatId, this.senderId, this.receiverId, this.texto); }

// States
abstract class AdoptionState extends Equatable { @override List<Object?> get props => []; }
class AdoptionInitial extends AdoptionState {}
class AdoptionLoading extends AdoptionState {}
class AdoptionSuccess extends AdoptionState { final String msg; AdoptionSuccess(this.msg); @override List<Object?> get props => [msg]; }
class AdoptionError extends AdoptionState { final String msg; AdoptionError(this.msg); @override List<Object?> get props => [msg]; }
class RequestsLoaded extends AdoptionState { final List<AdoptionRequest> requests; RequestsLoaded(this.requests); @override List<Object?> get props => [requests]; }

// BLoC
class AdoptionBloc extends Bloc<AdoptionEvent, AdoptionState> {
  final AdoptionRepository _repo;
  final RequestAdoptionUseCase _reqUseCase;
  final UpdateAdoptionStatusUseCase _updateUseCase;

  AdoptionBloc(this._repo, this._reqUseCase, this._updateUseCase) : super(AdoptionInitial()) {
    on<RequestAdoptionE>(_onRequest);
    on<UpdateStatusEvent>(_onUpdate);
    on<DonateEvent>(_onDonate);
    on<ConfirmDonationEvent>(_onConfirm);
    on<SendMessageEvent>(_onSend);
  }

  Future<void> _onRequest(RequestAdoptionE e, Emitter<AdoptionState> emit) async {
    emit(AdoptionLoading());
    try {
      final has = await _repo.hasRequest(e.petId, e.adoptanteId);
      if (has) { emit(AdoptionError('Ya enviaste una solicitud para esta mascota.')); return; }
      await _reqUseCase.execute(
        petId: e.petId,
        petNombre: e.petNombre,
        adoptanteId: e.adoptanteId,
        publicadorId: e.publicadorId,
        mensaje: e.mensaje,
        motivo: e.motivo,
        experiencia: e.experiencia,
        hogar: e.hogar,
        otrosDetalles: e.otrosDetalles,
      );
      emit(AdoptionSuccess('Solicitud enviada correctamente.'));
    } catch (ex) { emit(AdoptionError(ex.toString())); }
  }

  Future<void> _onUpdate(UpdateStatusEvent e, Emitter<AdoptionState> emit) async {
    emit(AdoptionLoading());
    try { await _updateUseCase.execute(e.reqId, e.status); emit(AdoptionSuccess('Estado actualizado.')); }
    catch (ex) { emit(AdoptionError(ex.toString())); }
  }

  Future<void> _onDonate(DonateEvent e, Emitter<AdoptionState> emit) async {
    emit(AdoptionLoading());
    try {
      await _repo.createDonation(petId: e.petId, donorId: e.donorId, donorNombre: e.donorNombre, monto: e.monto, nequiReceptor: e.nequiReceptor, nequiDonador: e.nequiDonador, motivo: e.motivo);
      emit(AdoptionSuccess('Donacion registrada. Una vez el dueno confirme el pago se sumara al total.'));
    } catch (ex) { emit(AdoptionError(ex.toString())); }
  }

  Future<void> _onConfirm(ConfirmDonationEvent e, Emitter<AdoptionState> emit) async {
    emit(AdoptionLoading());
    try { await _repo.confirmDonation(e.donationId); emit(AdoptionSuccess('Pago confirmado. El total ha sido actualizado.')); }
    catch (ex) { emit(AdoptionError(ex.toString())); }
  }

  Future<void> _onSend(SendMessageEvent e, Emitter<AdoptionState> emit) async {
    try { await _repo.sendMessage(chatId: e.chatId, senderId: e.senderId, receiverId: e.receiverId, texto: e.texto); }
    catch (ex) { emit(AdoptionError(ex.toString())); }
  }
}
